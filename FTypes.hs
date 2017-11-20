{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeSynonymInstances #-}

module FTypes where

import Foreign.Ptr
import Foreign.C.Types
import Foreign.C.String


-- State
-- -- Datastack
-- -- Compile Flag
-- -- Input String
-- -- Print String
-- -- Dictionary

data FState = FState
            { datastack     :: FDataStack
            , input_string  :: FInput
            , output_string :: FOutput
            , dictionary    :: FDict
            , compile_flag  :: FCFlag
            , return_stack  :: FRStack
            , quit_flag     :: Bool
            , abort_flag    :: Bool
            , dsp_action    :: DSPAction
            } deriving (Show)

-- Type aliases
type FInput = String
type FOutput = String
type FDataStack = [FStackItem]
type FDictEntry = (String, FIWord, FStackItem) --FStackItem is of type FCFn
type FDict = [FDictEntry]
type FCFlag = Bool
type FCFn = [FStackItem]
type FRStack = [FState] --what should this type be?!
type FList = [FStackItem]

data FIWord = Imm
            | Not
            | NA deriving (Show, Eq)

-- Stack content options
data FStackItem = FNum Integer
                | FStr String
                | FFn  (FState -> FState)
                | FCFn [FStackItem]
                | FIWord FIWord
                | FCFlag Bool
                | FList [FStackItem]

instance Show FStackItem where
    show (FNum x) = show x
    show (FCFlag x) = show x
    show (FStr []) = ""
    show (FStr x) = x
    show (FFn  _) = "<function>"
    show (FCFn _) = "[composite fn]"
    show (FIWord x) = show x
    show (FList []) = "[]"
    show (FList (x:[])) = show x
    show (FList x) = show (head x) ++ show (tail x)

-- DSP Types

type DSPEnvironment = ( [ModAvailable], DSPRuntime )

instance {-# OVERLAPS #-} Show DSPEnvironment where
    show (mlist, (mods, patches)) =
        "Mods:\t"
     ++ concat (map (++ "\n\t")(map (show . fst) mlist))
     ++ "\nRuntime:\nMods:\t" ++ shows (length mods) "\n"
     ++ concat (map (++ "\n")(map (show) mods))
     ++ "\nPaxes:\t" ++ shows (length patches) "\n"
     ++ concat (map (++ "\n")(map (show) patches))
     ++ "\n"

type ModAvailable = ( ModType, FunPtr () )

type ModType = String

instance {-# OVERLAPS #-} Show ModType where
    show m = m
    -- just forces no quote marks around names

type InName = String
type ParamName = String
type OutName = String

type DSPRuntime = ( [ActiveMod], [ActivePatch] )

data ActiveMod = ActiveMod
               { mtype   :: ModType
               , mindex  :: Int
               , address :: IO (Ptr ())
               , ins     :: [ModIn]
               , params  :: [ModParam]
               , outs    :: [ModOut]
               }

instance Show ActiveMod where
    show m = shows (mtype m) "\t"
          ++ shows (mindex m) "\n\t"
          ++ shows (ins m) "\n\t"
          ++ shows (params m) "\n\t"
          ++ shows (outs m) "\n\t"
          ++ "}"

type ModIn = (InName, InAddress)
type ModParam = (ParamName, ParamSetter, ParamValue)
type ModOut = (OutName, OutAddress)

type InAddress = Ptr ()
type ParamSetter = FunPtr ()
type ParamValue = Double
type OutAddress = Ptr ()

type ActivePatch = (PatchIx, PatchSrc, PatchDst)
type PatchIx  = Int
type PatchSrc = (ActiveMod, ModOut)
type PatchDst = (ActiveMod, ModIn)

instance {-# OVERLAPS #-} Show [ActivePatch] where
    show plist = "Patches:\n" ++
        concat (map (++ "\n")(map (show) plist ))

instance {-# OVERLAPS #-} Show ActivePatch where
    show (ix, src, dst) = shows ix "\t"
        ++ shows (mindex (fst src)) "."
            ++ shows (mtype (fst src)) "."
            ++ shows (fst $ snd src) "\t -> "
        ++ shows (mindex (fst dst)) "."
            ++ shows (mtype (fst dst)) "."
            ++ show (fst $ snd dst)

data DSPAction = None
               | NewMod ModAvailable
               | ListParams ActiveMod
               | GetParam ActiveMod
               | SetParam ParamSetter ActiveMod
               | ListInputs ActiveMod
               | NewPatch ActiveMod ActiveMod
               deriving (Show)
