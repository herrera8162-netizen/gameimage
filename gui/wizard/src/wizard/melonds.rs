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
    , common::Msg::DrawMelondsIcon);
} // }}}

// pub fn icon() {{{
pub fn icon(tx: Sender<common::Msg>, title: &str)
{
  frame::icon::project(tx.clone()
    , title
    , common::Msg::DrawMelondsName
    , common::Msg::DrawMelondsIcon
    , common::Msg::DrawMelondsRom
  );
} // }}}

// pub fn rom() {{{
pub fn rom(tx: Sender<common::Msg>, title: &str)
{
  wizard::install::install(tx.clone()
    , title
    , "rom"
    , common::Msg::DrawMelondsIcon
    , common::Msg::DrawMelondsRom
    , common::Msg::DrawMelondsBios);
} // }}}

// pub fn bios() {{{
pub fn bios(tx: Sender<common::Msg>, title: &str)
{
  // Bios/firmware are optional for melonDS - it supports direct-boot without
  // them - but installing them here still reuses the same generic install
  // step other platforms use for their (mandatory) bios files.
  wizard::install::install(tx.clone()
    , title
    , "bios"
    , common::Msg::DrawMelondsRom
    , common::Msg::DrawMelondsBios
    , common::Msg::DrawMelondsTest);
} // }}}

// pub fn test() {{{
pub fn test(tx: Sender<common::Msg>, title: &str)
{
  wizard::test::test(tx.clone()
    , title
    , common::Msg::DrawMelondsBios
    , common::Msg::DrawMelondsTest
    , common::Msg::DrawMelondsCompress);
} // }}}

// pub fn compress() {{{
pub fn compress(tx: Sender<common::Msg>, title: &str)
{
  wizard::compress::compress(tx.clone()
    , title
    , common::Msg::DrawMelondsTest
    , common::Msg::DrawMelondsCompress
    , common::Msg::DrawCreator);
} // }}}

// vim: set expandtab fdm=marker ts=2 sw=2 tw=100 et :
