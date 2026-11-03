import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://knpvwskfsteonmfmajdm.supabase.co';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_eoVBTJMtPK03t7ZHFcK9Lg_V5wqszPe';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});

// Helper untuk memeriksa status koneksi Supabase
export const checkSupabaseConnection = async () => {
  try {
    const { data, error } = await supabase.from('profiles').select('count', { count: 'exact', head: true });
    if (error && error.code === '42P01') {
      // Tabel belum dibuat di SQL Editor
      return { connected: true, tablesReady: false, error: 'Tabel database belum dibuat di SQL Editor Supabase.' };
    }
    return { connected: !error, tablesReady: !error, error: error ? error.message : null };
  } catch (err) {
    return { connected: false, tablesReady: false, error: err.message };
  }
};
