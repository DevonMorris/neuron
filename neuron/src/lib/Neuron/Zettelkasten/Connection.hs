{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Neuron.Zettelkasten.Connection where

import Data.Aeson
import Data.Default (Default (..))
import Relude hiding (show)
import Text.Pandoc.Definition (Block)
import Text.Read
import Text.Show (Show (show))

-- | Represent the connection between zettels
data Connection
  = -- | A folgezettel points to a zettel that is conceptually a *part* of the
    -- parent zettel.
    Folgezettel
  | -- | Any other ordinary connection (eg: "See also")
    OrdinaryConnection
  deriving (Eq, Ord, Enum, Bounded, Generic)

instance FromJSON Connection where
  parseJSON = maybe (fail "Unknown connection") pure . readMaybe <=< parseJSON

instance ToJSON Connection where
  toJSON = toJSON . show

instance Default Connection where
  def = OrdinaryConnection

instance Semigroup Connection where
  -- A folgezettel link trumps all other kinds in that zettel.
  Folgezettel <> _ = Folgezettel
  _ <> Folgezettel = Folgezettel
  OrdinaryConnection <> OrdinaryConnection = OrdinaryConnection

instance Show Connection where
  show = \case
    Folgezettel -> "folge"
    OrdinaryConnection -> "cf"

instance Read Connection where
  readsPrec _ s
    | s == show Folgezettel = [(Folgezettel, "")]
    | s == show OrdinaryConnection = [(OrdinaryConnection, "")]
    | otherwise = []

-- | A connection with context represented by Pandoc blocks
type ContextualConnection = (Connection, [Block])