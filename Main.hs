{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Web.Scotty
import qualified Data.Text.Lazy as TL
import Data.Text.Lazy.Encoding (decodeUtf8)
import Data.Monoid ((<>))
import Control.Monad.IO.Class
import SqlTypes
import Data.Aeson (FromJSON, ToJSON, encode, decode)
import GHC.Generics
import Database.SQLite.Simple
import Database.SQLite.Simple.ToField
import qualified Data.ByteString.Lazy.Char8 as BS

getUserQuery = "select id, first_name, second_name, team from users"
getUserQueryId = "select id, first_name, second_name, team from users where id = (?)"
insertUserQuery = "insert into users (first_name, second_name, team) values (?, ?, ?)"
updateUserQuery = "update users set first_name = (?), second_name = (?), team = (?) where id = (?)"

routes :: Connection -> ScottyM ()
routes conn = do
    get "/hello" 
        hello
    get "/hello/:name" $ do
        name <- param "name"
        helloName name
    get "/users" $ do
        users <- liftIO (getUsers conn)
        json users
    put "/users" $ do
        user <- jsonData :: ActionM User
        liftIO (insertUser conn user)
        json user
    get "/users/:id" $ do
        id <- param "id" :: ActionM TL.Text
        user <- liftIO (getUser conn id)
        json user


hello :: ActionM ()
hello = do
    text "hello world!"

helloName :: TL.Text -> ActionM ()
helloName name = do
    text ("hello " <> name <> " :*")

getUsers :: Connection -> IO [User]
getUsers conn = do
    users <- query_ conn getUserQuery :: IO [User]
    return users

getUser :: Connection -> TL.Text -> IO User
getUser conn id = do
    users <- query conn getUserQueryId (Only id) :: IO [User]
    return (head users)

insertUser :: Connection -> User -> IO ()
insertUser conn user = do
    if null $ userId user 
        then execute conn insertUserQuery user
        else execute conn updateUserQuery (firstName user, lastName user, teamId user, userId user)

main = do
    conn <- open "data.db"
    scotty 3000 (routes conn)
