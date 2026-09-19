# src/git/c/config.cr
@[Link("git2")]
lib LibGit2
  # ============================================================================
  # CONFIG (git2/config.h)
  # ============================================================================

  enum ConfigLevel
    SYSTEM        =  2
    XDG           =  3
    GLOBAL        =  4
    LOCAL         =  5
    WORKTREE      =  6
    APP           =  7
    HIGHEST_LEVEL = -1
  end

  struct ConfigEntry
    name          : LibC::Char*
    value         : LibC::Char*
    backend_type  : LibC::Char*
    origin_path   : LibC::Char*
    include_depth : LibC::UInt
    level         : ConfigLevel
  end

  type ConfigIterator = Void*

  alias ConfigForeachCb = (ConfigEntry*, Void* -> LibC::Int)

  fun config_entry_free = git_config_entry_free(entry : ConfigEntry*)

  fun config_find_global = git_config_find_global(out_buf : Buf*) : LibC::Int
  fun config_find_xdg = git_config_find_xdg(out_buf : Buf*) : LibC::Int
  fun config_find_system = git_config_find_system(out_buf : Buf*) : LibC::Int

  fun config_open_default = git_config_open_default(out_cfg : Config*) : LibC::Int
  fun config_new = git_config_new(out_cfg : Config*) : LibC::Int
  fun config_open_ondisk = git_config_open_ondisk(out_cfg : Config*, path : LibC::Char*) : LibC::Int
  fun config_open_level = git_config_open_level(out_cfg : Config*, parent : Config, level : ConfigLevel) : LibC::Int
  fun config_open_global = git_config_open_global(out_cfg : Config*, config : Config) : LibC::Int

  fun config_snapshot = git_config_snapshot(out_cfg : Config*, config : Config) : LibC::Int
  fun config_free = git_config_free(cfg : Config)

  fun config_get_entry = git_config_get_entry(out_entry : ConfigEntry**, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_int32 = git_config_get_int32(out_val : LibC::Int32*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_int64 = git_config_get_int64(out_val : Int64*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_bool = git_config_get_bool(out_val : LibC::Int*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_path = git_config_get_path(out_buf : Buf*, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_string = git_config_get_string(out_val : LibC::Char**, cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_get_string_buf = git_config_get_string_buf(out_buf : Buf*, cfg : Config, name : LibC::Char*) : LibC::Int

  fun config_set_int32 = git_config_set_int32(cfg : Config, name : LibC::Char*, value : LibC::Int32) : LibC::Int
  fun config_set_int64 = git_config_set_int64(cfg : Config, name : LibC::Char*, value : Int64) : LibC::Int
  fun config_set_bool = git_config_set_bool(cfg : Config, name : LibC::Char*, value : LibC::Int) : LibC::Int
  fun config_set_string = git_config_set_string(cfg : Config, name : LibC::Char*, value : LibC::Char*) : LibC::Int
  fun config_set_multivar = git_config_set_multivar(cfg : Config, name : LibC::Char*, regexp : LibC::Char*, value : LibC::Char*) : LibC::Int

  fun config_delete_entry = git_config_delete_entry(cfg : Config, name : LibC::Char*) : LibC::Int
  fun config_delete_multivar = git_config_delete_multivar(cfg : Config, name : LibC::Char*, regexp : LibC::Char*) : LibC::Int

  fun config_foreach = git_config_foreach(cfg : Config, callback : ConfigForeachCb, payload : Void*) : LibC::Int
  fun config_iterator_new = git_config_iterator_new(out_iter : ConfigIterator*, cfg : Config) : LibC::Int
  fun config_iterator_glob_new = git_config_iterator_glob_new(out_iter : ConfigIterator*, cfg : Config, regexp : LibC::Char*) : LibC::Int
  fun config_next = git_config_next(entry : ConfigEntry**, iter : ConfigIterator) : LibC::Int
  fun config_iterator_free = git_config_iterator_free(iter : ConfigIterator)
end
