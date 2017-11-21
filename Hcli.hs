{-# LANGUAGE ForeignFunctionInterface #-}

module Hcli where

-- FFI for being called by C
import Foreign.Ptr
import Foreign.C.Types
import Foreign.C.String
import Foreign.Storable
import System.Environment
import Data.List
import Data.Char
import Dict
import DSP
import FTypes

-- TODO
--
-- dsp is now being sent to fQUIT. next we need to make it do smething!
-- this should happen in the dsp_act section.
-- start with print & create mod bc the fns already work.
--
-- nb: dsp_act now takes an action & a DSPEnv, returns DSPEnv
-- this means dsp_actions should be completely isolated from forth
-- only used for IO to the C system (things that can't be done directly)
-- nb: 'getters' should be able to act without a dsp_action
--     'patches' also need not touch dsp_act
-- -- it's really only for createmod & set param (delete mod)
-- -- perhaps 'createpatch' needs to set a flag to force recompilation?
--
-- write fns to correctly populate ins, params & outs from c
-- -- will require expanded c-header stubs
-- -- perhaps time to refactor them to just be a data blob
-- -- don't really need to rewrite that fn in each header
-- -- just make 1 data-accessor in the dsp_cli.h
-- -- NOT IO, bc they are guaranteed to match the mtype
--
-- dspInit should instantiate the IO module

-- forth dictionary
-- nb: need at least 1 space after ;
hoth_defns = ": SQ (     a -- a^2 ) DUP * ;          "
          ++ ": CUBED (  a -- a^3 ) DUP DUP * * ;    "
          ++ ": NIP (  a b -- a ) SWAP DROP ;        "
          ++ ": TUCK ( a b -- b a b ) DUP ROT SWAP ; "
          ++ ": OVER ( a b -- a b a ) SWAP TUCK ;    "
--          ++ " : PI (    -- )DUP * 355 113 */ ;"


foreign export ccall hs_cli :: IO CInt
-- set initial state
hs_cli :: IO CInt
hs_cli = do
    dspEnv <- dspInit
    env2 <- dspCreateMod dspEnv (head $ fst dspEnv)
    env3 <- dspCreateMod env2 $ (fst dspEnv)!!1
    let m1 = (fst $ snd env3)!!0 -- grabbing direct indexes (dangerous)
    let m2 = (fst $ snd env3)!!1
    let patchPtr = dspPatch (env3)
                            (m1)
                            (head $ ins m1)
                            (m2)
                            (head $ outs m2)
    putStrLn (show patchPtr)
    iState <- fQUIT (FState { datastack     = []
                           , input_string  = hoth_defns
                           , output_string = ""
                           , dictionary    = native_dict
                           , compile_flag  = False
                           , return_stack  = []
                           , quit_flag     = False
                           , abort_flag    = False
                           , dsp_action    = None
                           }
                    , patchPtr)
    repl iState

repl :: HothS
     -> IO CInt
repl (state, dsp) = do
    accept_me <- getLine
    newState <- fQUIT (fACCEPT accept_me $ state
                      , dsp)
    putStrLn (output_string $ fst newState)
    if (quit_flag $ fst newState)
        then return (1)
        else repl (clear $ fst newState, dsp)
    where
        fACCEPT a st = st { input_string = a }
        clear s = s { output_string = "" }
