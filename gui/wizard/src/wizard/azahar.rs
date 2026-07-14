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
    , common::Msg::DrawAzaharIcon);
} // }}}

// pub fn icon() {{{
pub fn icon(tx: Sender<common::Msg>, title: &str)
{
  frame::icon::project(tx.clone()
    , title
    , common::Msg::DrawAzaharName
    , common::Msg::DrawAzaharIcon
    , common::Msg::DrawAzaharRom
  );
} // }}}

// pub fn rom() {{{
pub fn rom(tx: Sender<common::Msg>, title: &str)
{
  wizard::install::install(tx.clone()
    , title
    , "rom"
    , common::Msg::DrawAzaharIcon
    , common::Msg::DrawAzaharRom
    , common::Msg::DrawAzaharBios);
} // }}}

// pub fn bios() {{{
pub fn bios(tx: Sender<common::Msg>, title: &str)
{
  // boot9.bin/boot11.bin (+ optional seeddb.bin) are needed for decrypting
  // commercial 3DS content; homebrew/decrypted content can run without them.
  wizard::install::install(tx.clone()
    , title
    , "bios"
    , common::Msg::DrawAzaharRom
    , common::Msg::DrawAzaharBios
    , common::Msg::DrawAzaharTest);
} // }}}

// pub fn test() {{{
pub fn test(tx: Sender<common::Msg>, title: &str)
{
  wizard::test::test(tx.clone()
    , title
    , common::Msg::DrawAzaharBios
    , common::Msg::DrawAzaharTest
    , common::Msg::DrawAzaharCompress);
} // }}}

// pub fn compress() {{{
pub fn compress(tx: Sender<common::Msg>, title: &str)
{
  wizard::compress::compress(tx.clone()
    , title
    , common::Msg::DrawAzaharTest
    , common::Msg::DrawAzaharCompress
    , common::Msg::DrawCreator);
} // }}}

// vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
