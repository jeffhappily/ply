-- | $module UPLC helpers.
module Ply.Core.UPLC (applyConstant) where

import Data.String (IsString)

import PlutusCore (Some (Some), ValueOf (ValueOf))
import qualified PlutusCore as PLC
import UntypedPlutusCore (
  DeBruijn (DeBruijn),
  DefaultFun,
  DefaultUni,
  Index,
  Program (Program),
  Term (Apply, Builtin, Constant, Delay, Error, Force, LamAbs, Var),
  Version,
 )

pattern DefaultVersion :: Version ()
pattern DefaultVersion <-
  ((== PLC.defaultVersion ()) -> True)
  where
    DefaultVersion = PLC.defaultVersion ()

-- | Apply a 'DefaultUni' constant to given UPLC program, inlining if necessary.
applyConstant ::
  Program DeBruijn DefaultUni DefaultFun () ->
  Some (ValueOf DefaultUni) ->
  Program DeBruijn DefaultUni DefaultFun ()
applyConstant (Program () DefaultVersion f@(LamAbs () _ body)) c =
  Program () DefaultVersion $
    let arg = Constant () c
     in if isSmallConstant c then subst 1 (const body) f else Apply () f arg
applyConstant (Program () v t) _ =
  error $
    "applyConstant: unsupported program; expected version: " ++ show DefaultVersion
      ++ "; expected term: LamAbs\n"
      ++ "actual version: "
      ++ show v
      ++ "; actual term: "
      ++ termIdOf t

-- | Name of UPLC terms, for usage in friendly error messages.
termIdOf :: IsString p => Term name uni fun () -> p
termIdOf (Constant () _) = "Constant"
termIdOf (Builtin () _) = "Builtin"
termIdOf (Error ()) = "Error"
termIdOf (Var () _) = "Var"
termIdOf (Apply () _ _) = "Apply"
termIdOf (LamAbs () _ _) = "LamAbs"
termIdOf (Delay () _) = "Delay"
termIdOf (Force () _) = "Force"

isSmallConstant :: Some (ValueOf DefaultUni) -> Bool
isSmallConstant c = case c of
  -- These constants are smaller than variable references.
  Some (ValueOf PLC.DefaultUniBool _) -> True
  Some (ValueOf PLC.DefaultUniUnit _) -> True
  Some (ValueOf PLC.DefaultUniInteger n) | n < 256 -> True
  _ -> False

-- From Plutarch, with slight modifications.
subst ::
  Index ->
  (Index -> Term DeBruijn DefaultUni DefaultFun ()) ->
  Term DeBruijn DefaultUni DefaultFun () ->
  Term DeBruijn DefaultUni DefaultFun ()
subst idx x (Apply () yx yy) = Apply () (subst idx x yx) (subst idx x yy)
subst idx x (LamAbs () name y) = LamAbs () name (subst (idx + 1) x y)
subst idx x (Delay () y) = Delay () (subst idx x y)
subst idx x (Force () y) = Force () (subst idx x y)
subst idx x (Var () (DeBruijn idx')) | idx == idx' = x idx
subst idx _ y@(Var () (DeBruijn idx')) | idx > idx' = y
subst idx _ (Var () (DeBruijn idx')) | idx < idx' = Var () (DeBruijn $ idx' - 1)
subst _ _ y = y