{- |
Module     : Spec.Effect.TreasuryWithdrawalEffect
Maintainer : seungheon.ooh@gmail.com
Description: Sample based testing for Treasury Withdrawal Effect

This module tests the Treasury Withdrawal Effect.
-}
module Spec.Effect.TreasuryWithdrawal (tests) where

import Agora.Effect.TreasuryWithdrawal (
  TreasuryWithdrawalDatum (TreasuryWithdrawalDatum),
  treasuryWithdrawalValidator,
 )
import Plutus.V1.Ledger.Value qualified as Value
import Sample.Effect.TreasuryWithdrawal (
  buildReceiversOutputFromDatum,
  buildScriptContext,
  currSymbol,
  inputCollateral,
  inputGAT,
  inputTreasury,
  inputUser,
  outputTreasury,
  outputUser,
  treasuries,
  users,
 )
import Test.Tasty (TestTree, testGroup)
import Test.Util (effectFailsWith, effectSucceedsWith)

tests :: [TestTree]
tests =
  [ testGroup
      "effect"
      [ effectSucceedsWith
          "Simple"
          (treasuryWithdrawalValidator currSymbol)
          datum1
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 1 (asset1 10)
              ]
              $ outputTreasury 1 (asset1 7) :
              buildReceiversOutputFromDatum datum1
          )
      , effectSucceedsWith
          "Simple with multiple treasuries "
          (treasuryWithdrawalValidator currSymbol)
          datum1
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 1 (asset1 10)
              , inputTreasury 2 (asset1 100)
              , inputTreasury 3 (asset1 500)
              ]
              $ [ outputTreasury 1 (asset1 7)
                , outputTreasury 2 (asset1 100)
                , outputTreasury 3 (asset1 500)
                ]
                ++ buildReceiversOutputFromDatum datum1
          )
      , effectSucceedsWith
          "Mixed Assets"
          (treasuryWithdrawalValidator currSymbol)
          datum2
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 1 (asset1 20)
              , inputTreasury 2 (asset2 20)
              ]
              $ [ outputTreasury 1 (asset1 13)
                , outputTreasury 2 (asset2 14)
                ]
                ++ buildReceiversOutputFromDatum datum2
          )
      , effectFailsWith
          "Pay to uknown 3rd party"
          (treasuryWithdrawalValidator currSymbol)
          datum2
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 1 (asset1 20)
              , inputTreasury 2 (asset2 20)
              ]
              $ [ outputUser 100 (asset1 2)
                , outputTreasury 1 (asset1 11)
                , outputTreasury 2 (asset2 14)
                ]
                ++ buildReceiversOutputFromDatum datum2
          )
      , effectFailsWith
          "Missing receiver"
          (treasuryWithdrawalValidator currSymbol)
          datum2
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 1 (asset1 20)
              , inputTreasury 2 (asset2 20)
              ]
              $ [ outputTreasury 1 (asset1 13)
                , outputTreasury 2 (asset2 14)
                ]
                ++ drop 1 (buildReceiversOutputFromDatum datum2)
          )
      , effectFailsWith
          "Unauthorized treasury"
          (treasuryWithdrawalValidator currSymbol)
          datum3
          ( buildScriptContext
              [ inputGAT
              , inputCollateral 10
              , inputTreasury 999 (asset1 20)
              ]
              $ outputTreasury 999 (asset1 17) :
              buildReceiversOutputFromDatum datum3
          )
      , effectFailsWith
          "Prevent transactions besides the withdrawal"
          (treasuryWithdrawalValidator currSymbol)
          datum3
          ( buildScriptContext
              [ inputGAT
              , inputTreasury 1 (asset1 20)
              , inputTreasury 999 (asset1 20)
              , inputUser 99 (asset2 100)
              ]
              $ [ outputTreasury 1 (asset1 17)
                , outputUser 100 (asset2 100)
                ]
                ++ buildReceiversOutputFromDatum datum3
          )
      ]
  ]
  where
    asset1 = Value.singleton "abbc12" "OrangeBottle"
    asset2 = Value.singleton "abbc12" "19721121"
    datum1 =
      TreasuryWithdrawalDatum
        [ (head users, asset1 1)
        , (users !! 1, asset1 1)
        , (users !! 2, asset1 1)
        ]
        [ treasuries !! 1
        , treasuries !! 2
        , treasuries !! 3
        ]
    datum2 =
      TreasuryWithdrawalDatum
        [ (head users, asset1 4 <> asset2 5)
        , (users !! 1, asset1 2 <> asset2 1)
        , (users !! 2, asset1 1)
        ]
        [ head treasuries
        , treasuries !! 1
        , treasuries !! 2
        ]
    datum3 =
      TreasuryWithdrawalDatum
        [ (head users, asset1 1)
        , (users !! 1, asset1 1)
        , (users !! 2, asset1 1)
        ]
        [treasuries !! 1]
