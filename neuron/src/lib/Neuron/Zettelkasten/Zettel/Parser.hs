{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Neuron.Zettelkasten.Zettel.Parser where

import Data.Dependent.Map (DMap)
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import Data.Some (Some (..))
import Data.TagTree (Tag, unTag)
import qualified Data.Text as T
import Neuron.Markdown (parseMarkdown)
import Neuron.Plugin.PluginData (PluginZettelData)
import Neuron.Zettelkasten.ID (Slug, ZettelID (unZettelID))
import Neuron.Zettelkasten.Query.Parser (parseQueryLink)
import Neuron.Zettelkasten.Zettel
import qualified Neuron.Zettelkasten.Zettel.Meta as Meta
import Relude
import Text.Pandoc.Definition (Pandoc)
import qualified Text.Pandoc.LinkContext as LC
import qualified Text.Pandoc.Util as P
import qualified Text.URI as URI

type QueryExtractor = Pandoc -> ZettelQueries

parseZettel ::
  QueryExtractor ->
  FilePath ->
  ZettelID ->
  Text ->
  DMap PluginZettelData Identity ->
  ZettelC
parseZettel queryExtractor fn zid s pluginData = do
  case parseMarkdown fn s of
    Left parseErr ->
      let slug = mkDefaultSlug $ unZettelID zid
       in Left $ Zettel zid slug fn "Unknown" False Set.empty Nothing False ([], []) (s, parseErr) pluginData
    Right (meta, doc) ->
      let -- Determine zettel title
          (title, titleInBody) = case Meta.title =<< meta of
            Just tit -> (tit, False)
            Nothing -> fromMaybe (unZettelID zid, False) $ do
              (,True) . P.plainify . snd <$> P.getH1 doc
          -- Accumulate queries
          queries@(_, tagQueries) = queryExtractor doc
          -- Determine zettel tags
          metaTags = fromMaybe [] $ Meta.tags =<< meta
          queryTags = getInlineTag `mapMaybe` tagQueries
          tags = Set.fromList $ metaTags <> queryTags
          -- Determine other metadata
          date = Meta.date =<< meta
          slug = fromMaybe (mkDefaultSlug $ unZettelID zid) $ Meta.slug =<< meta
          unlisted = Just True == (Meta.unlisted =<< meta)
       in Right $
            Zettel zid slug fn title titleInBody tags date unlisted queries doc pluginData
  where
    _dirFolgezettelMarkdown (unTag -> tag) =
      "\n\n" <> "[[[z:zettels?tag=" <> tag <> "/*]]]"
    getInlineTag :: Some ZettelQuery -> Maybe Tag
    getInlineTag = \case
      Some (ZettelQuery_TagZettel tag) -> Just tag
      _ -> Nothing
    mkDefaultSlug :: Text -> Slug
    mkDefaultSlug ss =
      foldl' (\s' x -> T.replace x "_" s') ss (charsDisallowedInURL <> [" "])
    charsDisallowedInURL :: [Text]
    charsDisallowedInURL =
      [":"]

-- | Like `parseZettel` but operates on multiple files.
parseZettels ::
  QueryExtractor ->
  [(ZettelID, (FilePath, (Text, DMap PluginZettelData Identity)))] ->
  [ZettelC]
parseZettels queryExtractor files =
  flip fmap files $ \(zid, (path, (s, pluginData))) ->
    parseZettel queryExtractor path zid s pluginData

extractQueriesWithContext :: QueryExtractor
extractQueriesWithContext doc =
  (lefts &&& rights) $
    mapMaybe (uncurry parseQueryLinkWithContext) $
      Map.toList $ LC.queryLinksWithContext doc
  where
    parseQueryLinkWithContext url (attrs, ctx) = do
      uri <- URI.mkURI url
      parseQueryLink attrs uri >>= \case
        Left x -> pure $ Left (x, ctx)
        Right x -> pure $ Right x
