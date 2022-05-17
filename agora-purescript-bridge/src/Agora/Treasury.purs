-- File auto generated by purescript-bridge! --
module Agora.Treasury where

import Prelude

import Data.Bounded.Generic (genericBottom, genericTop)
import Data.Enum (class Enum)
import Data.Enum.Generic (genericPred, genericSucc)
import Data.Generic.Rep (class Generic)
import Data.Lens (Iso', Lens', Prism', iso, prism')
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(..))
import Type.Proxy (Proxy(Proxy))

data TreasuryRedeemer = SpendTreasuryGAT

derive instance Generic TreasuryRedeemer _

instance Enum TreasuryRedeemer where
  succ = genericSucc
  pred = genericPred

instance Bounded TreasuryRedeemer where
  bottom = genericBottom
  top = genericTop

--------------------------------------------------------------------------------

_SpendTreasuryGAT :: Iso' TreasuryRedeemer Unit
_SpendTreasuryGAT = iso (const unit) (const SpendTreasuryGAT)