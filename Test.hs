{-# OPTIONS -Wno-unused-imports #-}
module Test where

import Render
import Test.HUnit
import Test.QuickCheck
import Data.Maybe
import Text.Parsec
import Text.Parsec.String

main :: IO ()
main = do
  _ <- runTestTT hUnitTests
  print "Tests completed!"

hUnitTests :: Test
hUnitTests = test [
    "" ~: "" ~: True ~=? testParseSectionHeader
  , "" ~: "" ~: True ~=? testParseFileAndLimits
  , "" ~: "" ~: True ~=? testParseFileReference
  ]

testParseSectionHeader :: Bool
testParseSectionHeader = do
  let pfx = " test {} "
  let sfx =  " test {{test}}  "
  case (parse parseSectionHeader "secitonHeaderTest" (pfx ++ "{{sectionHeader}}" ++ sfx)) of
    Right (SectionHeaderReference s s') -> (s == pfx) && (s' == sfx)
    Left e -> error $ show e

testParseFileAndLimits :: Bool 
testParseFileAndLimits = do 
  let fp = "abc/xyz.123"
  let t1 = fp ++ " "
  let t2 = fp ++ " 123 456 "
  let t3 = fp ++ " 123 456"
  let c1 = case (parse parseFileAndLimits "fileAndLimitsTest" t1) of
        Right (x, Nothing, Nothing) -> x == fp
        Left e  -> error $ show e
        _ -> error "?"
  let c2 = case (parse parseFileAndLimits "fileAndLimitsTest" t2) of
        Right (_, Just y, Just z) -> and [y == 123, z == 456]
        Left e  -> error $ show e
        _ -> error "?"
  let c3 = case (parse parseFileAndLimits "fileAndLimitsTest" t3) of
        Right (_, Just y, Just z) -> and [y == 123, z == 456]
        Left e  -> error $ show e
        _ -> error "?"
  and [c1, c2, c3]


testParseFileReference :: Bool
testParseFileReference = do
  let fp = "abc/xyz.123"
  let t1 =  "{{ file "++ fp ++" }}"
  let t2 =  "{{ file "++ fp ++" 10 20 }}"
  let c1 = case (parse parseFileReference "fileRefTest" t1) of
        Right (FileReference x Nothing) -> x == fp
        Left e -> error $ show e
        _ -> error "?"
  let c2 = case (parse parseFileReference "fileRefTest" t2) of
        Right (FileReference x (Just (y',y''))) -> and [x == fp, y' == 10, y'' == 20]
        Left e -> error $ show e
        _ -> error "?"
  and [c1, c2]
