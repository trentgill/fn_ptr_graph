module FTypes where

-- State
-- -- Datastack
-- -- Compile Flag
-- -- Input String
-- -- Print String
-- -- Dictionary

data FState = FState
            { datastack :: FDataStack
            , input_string :: FInput
            , output_string :: FOutput
            , dictionary :: FDict
            , compile_flag :: FCFlag
            , return_stack :: FRStack
            , quit_flag :: Bool
            , abort_flag :: Bool
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
