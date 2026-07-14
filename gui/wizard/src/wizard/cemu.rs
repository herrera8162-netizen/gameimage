use fltk::app::Sender;

use crate::common;
use crate::frame;
use crate::wizard;

// pub fn name() {{{
pub fn name(tx: Sender<common::Msg>, title: &str)
{
  wizard::name::name(tx.clone()
    , title
    , common::Msg::DrawPlatform
    , common::Msg::DrawCemuIcon);
} // }}}

// pub fn icon() {{{
pub fn icon(tx: Sender<common::Msg>, title: &str)
{
  frame::icon::project(tx.clone()
    , title
    , common::Msg::DrawCemuName
    , common::Msg::DrawCemuIcon
    , common::Msg::DrawCemuRom
  );
} // }}}

// pub fn rom() {{{
pub fn rom(tx: Sender<common::Msg>, title: &str)
{
  wizard::install::install(tx.clone()
    , title
    , "rom"
    , common::Msg::DrawCemuIcon
    , common::Msg::DrawCemuRom
    , common::Msg::DrawCemuKeys);
} // }}}

// pub fn keys() {{{
pub fn keys(tx: Sender<common::Msg>, title: &str)
{
  // keys.txt (title keys for DLC/update decryption) is optional - only
  // needed for encrypted content.
  wizard::install::install(tx.clone()
    , title
    , "keys"
    , common::Msg::DrawCemuRom
    , common::Msg::DrawCemuKeys
    , common::Msg::DrawCemuTest);
} // }}}

// pub fn test() {{{
pub fn test(tx: Sender<common::Msg>, title: &str)
{
  wizard::test::test(tx.clone()
    , title
    , common::Msg::DrawCemuKeys
    , common::Msg::DrawCemuTest
    , common::Msg::DrawCemuCompress);
} // }}}

// pub fn compress() {{{
pub fn compress(tx: Sender<common::Msg>, title: &str)
{
  wizard::compress::compress(tx.clone()
    , title
    , common::Msg::DrawCemuTest
    , common::Msg::DrawCemuCompress
    , common::Msg::DrawCreator);
} // }}}

// vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
