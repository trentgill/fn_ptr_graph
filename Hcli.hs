{-# LANGUAGE ForeignFunctionInterface #-}

module Hcli where

-- FFI for being called by C
import Control.Monad  -- 'when'
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
import System.IO

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
--
-- both `.` and `.S` should act instantly through the same mechanism
-- as dsp_act. then there's less tricky value passing & ordering issues
-- to repl. thus repl expects sentences, while fQUIT expects words.
-- -- repl should print the forth 'ok' which says "i understood that
-- sentence" unless the 'abort_flag' is raised

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
    env2 <- dspCreateMod dspEnv $ (fst dspEnv)!!3
    env3 <- dspCreateMod env2 $ (fst dspEnv)!!1
    let sinez = (actMods $ snd env3)!!0
    let ioz   = (actMods $ snd env3)!!1
    patchPtr <- dspPatch (env3)
                         (sinez)
                         (head $ outs sinez)
                         (ioz)
                         (head $ ins ioz)
    e4 <- dsp_recompile patchPtr
    --putStrLn (show e4)
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
                    , e4)
    repl iState

repl :: HothS
     -> IO CInt
repl (state, dsp) = do
    hSetBuffering stdout NoBuffering
    putStr "> "
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
