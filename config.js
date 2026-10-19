// Supabase connection for the browser app (Project Settings → API).
// Both are safe to be public: the database's Row Level Security rules protect each showroom's data.
window.APP_CONFIG = {
  supabaseUrl: "https://jebszemeaycpkwzgznov.supabase.co",
  supabaseAnonKey: "sb_publishable_uwnMvzyj27Mmqzot9sMQeQ_O3QTtNw1" // publishable (public) key — never put a secret/service_role key here
};
