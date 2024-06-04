{-# LANGUAGE UndecidableInstances #-}

module Ply.Core.Internal.Reify (ReifyVersion (reifyVersion), ReifyRole (reifyRole), ReifyTypenames (reifyTypenames)) where

import Data.Kind (Constraint, Type)
import Data.Proxy (Proxy (Proxy))

import Ply.Core.Typename (PlyTypeName, plyTypeName)
import Ply.Core.Types

type ReifyVersion :: ScriptVersion -> Constraint
class ReifyVersion s where
  reifyVersion :: Proxy s -> ScriptVersion

type ReifyRole :: ScriptRole -> Constraint
class ReifyRole s where
  reifyRole :: Proxy s -> ScriptRole

type ReifyTypenames :: [Type] -> Constraint
class ReifyTypenames ts where
  reifyTypenames :: Proxy ts -> [Typename]

instance ReifyVersion ScriptV1 where
  reifyVersion _ = ScriptV1

instance ReifyVersion ScriptV2 where
  reifyVersion _ = ScriptV2

instance ReifyRole ThreeArgumentScript where
  reifyRole _ = ThreeArgumentScript

instance ReifyRole TwoArgumentScript where
  reifyRole _ = TwoArgumentScript

instance ReifyTypenames '[] where
  reifyTypenames _ = []

instance (PlyTypeName x, ReifyTypenames xs) => ReifyTypenames (x : xs) where
  reifyTypenames _ = plyTypeName @x : reifyTypenames (Proxy @xs)
