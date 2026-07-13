-- Sovereign Storyworks — locale helper
-- Phase 0 (Foundations & Spikes) | Features: L3

---Translate a locale key, with optional string.format arguments.
---Falls back to the key itself so a missing entry is visible, never a crash.
---@param key string
---@return string
function T(key, ...)
  local dict = Locales and Locales[Config.Locale]
  local str = dict and dict[key] or key
  if select('#', ...) > 0 then
    local ok, formatted = pcall(string.format, str, ...)
    if ok then return formatted end
  end
  return str
end
