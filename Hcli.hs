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
    dspFns <- dspInit
    putStrLn (show $ dspCreateMod (snd (head dspFns)))
    putStrLn (show dspFns)
    repl . fQUIT  -- process default input_string (extend dict)
         $ FState { datastack     = []
                  , input_string  = hoth_defns
                  , output_string = ""
                  , dictionary    = native_dict
                  , compile_flag  = False
                  , return_stack  = []
                  , quit_flag     = False
                  , abort_flag    = False
                  }

repl :: FState -> IO CInt -- takes state as input
repl state = do
    accept_me <- getLine
    let newState = fQUIT
                 . (fACCEPT accept_me)
                 $ state
    putStrLn (output_string newState)
    if (quit_flag newState)
        then return (1)
        else repl . clear $ newState
    where
        fACCEPT a st = st { input_string = a }
        clear s = s { output_string = "" }

-- Gather info about DSP environment
foreign import ccall "dsp_block.h hs_dspInit"
    c_dspInit :: CString

type DSPModDesc = (String, FunPtr ())

dspInit :: IO [DSPModDesc]
dspInit = do
    list <- findFns c_dspInit []
    return list
    where
        done :: String -> Bool
        done [] = True
        done _  = False
        findFns :: CString -> [DSPModDesc] -> IO [DSPModDesc]
        findFns ptr list = do
            str <- peekCString ptr
            fp <- peek (castPtr $ plusPtr ptr 16)
            if (done str)
                then return list
                else findFns (plusPtr ptr 24) ((str,fp):list)

foreign import ccall "dsp_block.h hs_dspCreateMod"
    c_dspCreateMod :: FunPtr () -> Ptr ()

dspCreateMod :: FunPtr () -> Ptr ()
dspCreateMod = c_dspCreateMod
