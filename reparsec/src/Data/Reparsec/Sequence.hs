{-# LANGUAGE BangPatterns #-}
-- | Parsing from an input list.

module Data.Reparsec.Sequence
  ( nextElement
  -- , endOfInput
  , expect
  , around
  , zeroOrMore
  ) where

import Data.Reparsec
import Data.Sequence (Seq(..))
import qualified Data.Sequence as Seq

-- | Wrap around something.
around ::
     (UnexpectedToken a1 e, NoMoreInput e, Eq a1, Monad m)
  => a1
  -> a1
  -> ParserT (Seq a1) e m a2
  -> ParserT (Seq a1) e m a2
around before after inner = expect before *> inner <* expect after

-- | Expect an element.
expect :: (UnexpectedToken a e, NoMoreInput e, Eq a, Monad m) => a -> ParserT (Seq a) e m ()
expect a = do
  a' <- nextElement
  if a == a'
    then pure ()
    else failWith (unexpectedToken a')

-- | Try to extract the next element from the input.
nextElement :: (NoMoreInput e, Monad m) => ParserT (Seq a) e m a
nextElement =
  ParserT
    (\mi0 pos more0 done failed ->
       let go mi more =
             case Seq.drop pos mi of
               (x :<| _) -> done mi (pos + 1) more x
               Empty ->
                 case more of
                   Complete -> failed mi pos more noMoreInputError
                   Incomplete ->
                     pure
                       (Partial
                          (\m ->
                             case m of
                               Nothing -> go mempty Complete
                               Just i -> go (mi <> i) more))
        in go mi0 more0)
{-# INLINABLE nextElement #-}

-- -- | Expect the end of input.
-- endOfInput :: (ExpectedEndOfInput e, Monad m) => ParserT (Seq a) e m ()
-- endOfInput =
--   ParserT (\mi0 done failed ->
--        let go mi =
--              case mi of
--                Just Empty -> pure (Partial go)
--                Just (_ :<| _) -> failed mi expectedEndOfInputError
--                Nothing -> done Nothing ()
--         in go mi0)
-- {-# INLINABLE endOfInput #-}

-- | Try to extract the next element from the input.
zeroOrMore :: (Semigroup e, Monad m) => ParserT (Seq a) e m b -> ParserT (Seq a) e m [b]
zeroOrMore elementParser = do
  result <- fmap Just elementParser <> pure Nothing
  case result of
    Nothing -> pure []
    Just element -> fmap (element :) (zeroOrMore elementParser)
{-# INLINABLE zeroOrMore #-}