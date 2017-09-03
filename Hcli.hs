{-# LANGUAGE ForeignFunctionInterface #-}

module Hcli where

-- FFI for being called by C
import Foreign.C.Types
import System.Environment
import Data.List
import Data.Char
import Dict
import FTypes

-- set initial state
cli_hs :: IO CInt
cli_hs = repl FState { datastack = []
                     , input_string = ""
                     , output_string = ""
                     , dictionary = native_dict
                     , compile_flag = False
                     , return_stack = []
                     , quit_flag = False
                     }

repl :: FState -> IO CInt -- takes state as input
repl state = do
    interpret_this <- getLine
    let inputState = state { input_string = interpret_this
                           , output_string = ""
                           }
    let retState = fQUIT inputState
    putStrLn (get_outstr retState)
    if (quit state) then return (1) else do
        repl retState
        where quit :: FState -> Bool
              quit = quit_flag
              get_outstr :: FState -> String
              get_outstr s@(FState {output_string=[]}) = "ok."
              get_outstr s = (output_string s)

foreign export ccall cli_hs :: IO CInt
