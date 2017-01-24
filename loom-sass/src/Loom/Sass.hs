{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Loom.Sass (
    Sass
  , SassError (..)
  , SassStyle (..)
  , findSassOnPath
  , compileSass
  , renderSassError
  ) where

import           Control.Monad.IO.Class (liftIO)

import qualified Data.Text as T

import           Loom.Process

import           P

import           System.FilePath (FilePath, takeDirectory)
import           System.Directory (createDirectoryIfMissing)
import           System.IO (IO)

import           X.Control.Monad.Trans.Either (EitherT)

newtype Sass =
  Sass {
      sassPath :: FilePath
    }

data SassError =
    SassProcessError ProcessError
  deriving (Show)

data SassStyle =
    SassNested
  | SassExpanded
  | SassCompact
  | SassCompressed
  deriving (Bounded, Enum, Eq, Show)

findSassOnPath :: IO (Maybe Sass)
findSassOnPath =
  fmap Sass <$> verifyExecutable "sassc"

compileSass :: Sass -> SassStyle -> FilePath -> FilePath -> EitherT SassError IO ()
compileSass sass style input outFile = do
  liftIO . createDirectoryIfMissing True . takeDirectory $ outFile
  firstT SassProcessError . call (sassPath sass) . mconcat $ [
      [T.pack input]
    , ["--style", renderSassStyle style]
    , [T.pack outFile]
    ]

renderSassError :: SassError -> Text
renderSassError se =
  case se of
    SassProcessError e ->
      "Error calling sassc: " <> renderProcessError e

renderSassStyle :: SassStyle -> Text
renderSassStyle ss =
  case ss of
    SassNested ->
      "nested"
    SassExpanded ->
      "expanded"
    SassCompact ->
      "compact"
    SassCompressed ->
      "compressed"

