{-# LANGUAGE TemplateHaskell #-}

{- |
Module     : Agora.Effect.TreasuryWithdrawal
Maintainer : seungheon.ooh@gmail.com
Description: An Effect that withdraws treasury deposit

An Effect that withdraws treasury deposit
-}
module Agora.Effect.TreasuryWithdrawal (TreasuryWithdrawalDatum, PTreasuryWithdrawalDatum, treasuryWithdrawalValidator) where

import GHC.Generics qualified as GHC
import Generics.SOP (Generic, I (I))

import Agora.Effect (makeEffect)
import Agora.Utils ( passert, passetClassValueOf' )
import Plutarch (popaque)
import Plutarch.Api.V1
    ( PTxInfo,
      PTxOutRef,
      PValidator,
      PTuple,
      PValue,
      PCredential,
      ptuple,
      PTxInInfo,
      PTxOut )
import Plutarch.DataRepr (
  DerivePConstantViaData (..),
  PDataFields,
  PIsDataReprInstances (..),
 )
import Plutarch.Lift (PUnsafeLiftDecl (..))
import Plutarch.Monadic qualified as P
import Plutus.V1.Ledger.Credential (Credential)
import Plutus.V1.Ledger.Value (AssetClass (..), CurrencySymbol, Value)
import PlutusTx qualified

data TreasuryWithdrawalDatum = TreasuryWithdrawalDatum {receivers :: [(Credential, Value)]}
  deriving stock (Show, GHC.Generic)
  deriving anyclass (Generic)

PlutusTx.makeLift ''TreasuryWithdrawalDatum
PlutusTx.unstableMakeIsData ''TreasuryWithdrawalDatum

data PTreasuryWithdrawalDatum (s :: S)
  = PTreasuryWithdrawalDatum
      ( Term
          s
          ( PDataRecord
              '["receivers" ':= PBuiltinList (PAsData (PTuple PCredential PValue))]
          )
      )
  deriving stock (GHC.Generic)
  deriving anyclass (Generic, PIsDataRepr)
  deriving
    (PlutusType, PIsData, PDataFields)
    via PIsDataReprInstances PTreasuryWithdrawalDatum

instance PUnsafeLiftDecl PTreasuryWithdrawalDatum where
  type PLifted PTreasuryWithdrawalDatum = TreasuryWithdrawalDatum
deriving via
  (DerivePConstantViaData TreasuryWithdrawalDatum PTreasuryWithdrawalDatum)
  instance
    (PConstant TreasuryWithdrawalDatum)

-- These functions can be replaced with ones on Utils.hs once seungheonoh/util branch get merged.
findOwnInput :: Term s (PTxInfo :--> PTxOutRef :--> PTxInInfo)
findOwnInput = phoistAcyclic $
  plam $ \txInfo spending' -> P.do
    input <- plet $ pfromData $ pfield @"inputs" # txInfo
    spending <- plet $ pdata spending'
    PJust result <- pmatch $ pfind # plam (\x -> pfield @"outRef" # x #== spending) # input
    pfromData result

findOwnAddress :: Term s (PTxInfo :--> PTxOutRef :--> PTxOut)
findOwnAddress = phoistAcyclic $
  plam $ \txInfo spending -> P.do
    pfromData $ pfield @"resolved" #$ findOwnInput # txInfo # spending

treasuryWithdrawalValidator :: forall {s :: S}. CurrencySymbol -> Term s PValidator
treasuryWithdrawalValidator currSymbol = makeEffect currSymbol $
  \_cs (datum' :: Term _ PTreasuryWithdrawalDatum) txOutRef' txInfo' -> P.do
    receivers <- plet $ pfromData $ pfield @"receivers" # datum'
    txInfo <- pletFields @'["outputs"] txInfo'
    let outputValues =
          pmap
            # plam
              ( \out' -> P.do
                  out <- pletFields @'["address", "value"] $ pfromData out'
                  cred <- pletFields @'["credential"] $ pfromData out.address
                  pdata $ ptuple # cred.credential # out.value
              )
            #$ txInfo.outputs
        outputContentMatchesRecivers =
          pall # plam id #$ pmap
            # plam (\out -> pelem # out # outputValues)
            #$ receivers
        outputNumberMatchesReceivers = plength # receivers #== plength # (pfromData txInfo.outputs)
        outputIsNotPayingToEffect = P.do
          input <- pletFields @'["address", "value"] $ findOwnAddress # pfromData txInfo' # txOutRef'
          let correctMinimum = passetClassValueOf' (AssetClass ("", "")) # input.value #== 2000000
              notPayingToEffect =
                pnot #$ pany
                  # plam
                    ( \x ->
                        input.address #== pfield @"address" # pfromData x
                    )
                  # pfromData txInfo.outputs
          correctMinimum #&& notPayingToEffect

    passert "Transaction output does not match receivers" outputContentMatchesRecivers
    passert "" outputNumberMatchesReceivers
    passert "" outputIsNotPayingToEffect

    popaque $ pconstant ()
