{-# OPTIONS -Wno-unused-imports #-}
{-# OPTIONS -Wno-type-defaults #-}
{-# Language OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE Strict #-}
{-# LANGUAGE StrictData #-}
module Test where

import Render
import Test.HUnit
import Test.QuickCheck
import Data.Maybe
import qualified Text.Parsec as TPar
import qualified Text.Parsec.String
import Data.List
import System.IO.Unsafe
import Text.Pretty.Simple (pPrint)
import Data.String.Conversions
import Data.Text (Text)
import QuasiText
import GHCi
import Debug.Trace
import Operations 

main :: IO ()
main = do
  _ <- runTestTT hUnitTests
  print "Tests completed!"

hUnitTests :: Test
hUnitTests = test [
    "testParseSectionHeader"    ~: True ~=? testParseSectionHeader
  , "testParseFileReference"    ~: True ~=? testParseFileReference
  , "testParseGhci"             ~: True ~=? testParseGhci
  , "testMultiLineXyz"          ~: True ~=? testMultiLineXyz
  , "testMultiLineXyz2"         ~: True ~=? testMultiLineXyz2
  , "testRealWorldSectionBlock" ~: True ~=? testRealWorldSectionBlock
  , "testRunGhci"               ~: testGhciRun
  , "testRunGhci2"              ~: testGhciRun2
  , "testRenderTemplate"        ~: testRenderTemplate
  ]

testParseSectionHeader :: Bool
testParseSectionHeader = do
  let pfx = " test {} "
  let sfx =  " test {{test}}  "
  case (TPar.parse parse "secitonHeaderTest" (pfx ++ "{{sectionHeader}}" ++ sfx)) of
    Right (SectionHeaderReference s s') -> (s == pfx) && (s' == sfx)
    Left e -> error $ show e


testParseFileReference :: Bool
testParseFileReference = do
  let fp = "abc/xyz.123"
  let t1 =  "{{file "++ fp ++"}}"
  let t2 =  "{{ file "++ fp ++" 10 20 }}"
  let c1 = case (TPar.parse  parse "fileRefTest" t1) of
        Right (FileReference x (FileLineRange Nothing)) -> x == fp
        Left e -> error $ show e
        _ -> error "?"
  let c2 = case (TPar.parse  parse "fileRefTest" t2) of
        Right (FileReference x (FileLineRange (Just (y',y'')))) -> and [x == fp, y' == 10, y'' == 20]
        Left e -> error $ show e
        _ -> error "?"
  and [c1, c2]

testParseGhci :: Bool
testParseGhci = do
  let t1 = concat $ intersperse "\\n" [
            "{{{ghci"
          , "hmmm"
          , "hmmm2"
          , "abcxyz}}}"
          ]
  case (TPar.parse parse "" t1) of
        Right (GHCiReference x) -> x == "\\nhmmm\\nhmmm2\\nabcxyz"
        Left e -> error $ show e

testMultiLineXyz :: Bool
testMultiLineXyz = do
  let t2 = concat $ intersperse "\\n" [
            "{{{ghci"
          , "hmmm"
          , "}}}"
          ]
  case (TPar.parse parseSection "testMultiLineXyz" t2) of
        (Right (SectionGHCi x:[])) -> unsafePerformIO $ do
          let expe = "\\nhmmm\\n"
          return $ x == expe
        (Left e) -> error $ show e
        (_) -> unsafePerformIO $ do
          return False


testMultiLineXyz2 :: Bool
testMultiLineXyz2 = do
  let t2 = concat $ intersperse "\\n" [
            "abcxyz"
          , "{{{ghci"
          , "hmm"
          , "hmm"
          , "}}}"
          , "abcxyz"
          ]
  case (TPar.parse parseSection "testMultiLineXyz" t2) of
        (Right (SectionRaw x:SectionGHCi y:SectionRaw x':[])) -> unsafePerformIO $ do
          return $
               (x == "abcxyz\\n")
            && (x' == "\\nabcxyz")
            && (y == "\\nhmm\\nhmm\\n")
        (Left e) -> error $ show e
        _ -> unsafePerformIO $ do
          return False

testRealWorldSectionBlock :: Bool
testRealWorldSectionBlock = do
   let t2 = concat $ intersperse "\\n" [
             "Testing"
           , "==========================================="
           , "```haskell"
           , "{-# LANGUAGE OverloadedStrings #-}"
           , "```"
           , "Or, abc xyz"
           , "-----------"
           ]
   case (TPar.parse parseSection "testMultiLineXyz" $ cs t2) of
        (Right (SectionRaw x:[])) -> unsafePerformIO $ do
          let expe = cs $ t2
          return $ x == expe
        (Left e) -> error $ show e
        (_) -> unsafePerformIO $ do
          return False

testGhciRun :: Test
testGhciRun = ("ghci> :t head\n      head :: [a] -> a") ~=? (unsafePerformIO $ runGhci ":t head")

testGhciRun2 :: Test
testGhciRun2 = "ghci> :t head\n      head :: [a] -> a\nghci> :t tail\n      tail :: [a] -> [a]"
  ~=? (unsafePerformIO $ runGhci ":t head\n:t tail")

testRenderTemplate :: Test
testRenderTemplate = do
  let input = [str|### Introducing Side-Effects

{{{ghci
  :t head
  4 + 4
}}}

testing123|] :: Text
  let sectionExpected = [
          SectionRaw "### Introducing Side-Effects\n\n"
        , SectionGHCi "  :t head\n  4 + 4\n"
        , SectionRaw "\n\ntesting123"
        ]
  unsafePerformIO $ case (TPar.parse parseSection "parseSection" $ cs input) of
    Right sections ->
      if (sections == sectionExpected) then do
        let textExpected = [
                "### Introducing Side-Effects"
              , ""
              , "{{{ghci\n  :t head\n  4 + 4\n}}}"
              , ""
              , ""
              , "testing123"]
        return $ textExpected ~=? transformInnerSection sections
      else do
        return $ sectionExpected ~=? sections
    Left e -> error $ show e
