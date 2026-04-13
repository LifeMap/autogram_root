module.exports = {
  apps: [
    {
      name: 'autogram-api-dev',
      script: '/Users/jaykim/Documents/twms/autogram/dev/api/src/server.js',
      instances: 1,
      exec_mode: 'fork',
      max_restarts: 10,
      restart_delay: 3000,
      max_memory_restart: '512M',
      out_file: '/var/log/autogram/dev-api-out.log',
      error_file: '/var/log/autogram/dev-api-error.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      watch: false,
      kill_timeout: 5000,
    },
  ],
};
