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

-- Gather info about DSP environment
-- foreign import ccall "dsp_block.h hs_dspInit"
--     c_dspInit :: CString
--
-- type DSPModDesc = (String, FunPtr ())
--
-- dspInit :: IO [DSPModDesc]
-- dspInit = do
--     list <- findFns c_dspInit []
--     return list
--     where
--         done :: String -> Bool
--         done [] = True
--         done _  = False
--         findFns :: CString -> [DSPModDesc] -> IO [DSPModDesc]
--         findFns ptr list = do
--             str <- peekCString ptr
--             fp <- peek (castPtr $ plusPtr ptr 16)
--             if (done str)
--                 then return list
--                 else findFns (plusPtr ptr 24) ((str,fp):list)
--
-- foreign import ccall "dsp_block.h hs_dspCreateMod"
--     c_dspCreateMod :: FunPtr () -> Ptr ()
--
-- dspCreateMod :: FunPtr () -> Ptr ()
-- dspCreateMod = c_dspCreateMod
--
-- foreign import ccall "dsp_block.h hs_dspGetIns"
--     c_dspGetIns :: Ptr () -> Ptr CInt
--
-- type DSPIns = (String, Ptr ())
--
-- dspGetIns :: Ptr () -> IO [DSPIns]
-- dspGetIns p = do
--     let pay = (c_dspGetIns p)
--     count <- peek pay
--     ppp  <- peek $ plusPtr pay 8
--     list <- getIns (ppp) (fromIntegral count) []
--     return list
--     where
--         getIns :: Ptr () -> Integer -> [DSPIns] -> IO [DSPIns]
--         getIns p 0 list = return list
--         getIns p c list = do
--             str <- peekCString (plusPtr p 8)
--             getIns (plusPtr p 24) (c-1) ((str,p):list)
--
-- foreign import ccall "dsp_block.h hs_dspGetParams"
--     c_dspGetParams :: Ptr () -> Ptr CInt
--
-- type DSPParams = (String, FunPtr (), FunPtr ())
--
-- dspGetParams :: Ptr () -> IO [DSPParams]
-- dspGetParams p = do
--     let pay = (c_dspGetParams p)
--     count <- peek pay
--     ppp  <- peek $ plusPtr pay 8
--     list <- getParams (ppp) (fromIntegral count) []
--     return list
--     where
--         getParams :: Ptr () -> Integer -> [DSPParams] -> IO [DSPParams]
--         getParams p 0 list = return list
--         getParams p c list = do
--             str <- peekCString ( plusPtr p 16 )
--             getParams (plusPtr p 32)
--                       (c-1)
--                       ( ( str
--                         , castPtrToFunPtr p
--                         , castPtrToFunPtr (plusPtr p 8)
--                         ) : list)
--
--
--
--
--foreign import ccall "dsp_block.h hs_dspPatch"
--    c_dspPatch :: Ptr () -> Ptr () -> Ptr () -> Ptr () -> Ptr ()
--
--dspPatch :: Ptr () -> Ptr () -> Ptr () -> Ptr () -> Ptr ()
--dspPatch = c_dspPatch
