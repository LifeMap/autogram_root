module.exports = {
  apps: [
    {
      name: 'autogram-api-prod',
      script: '/Users/jaykim/Documents/twms/autogram/prod/api/src/server.js',
      instances: 2,
      exec_mode: 'cluster',
      max_restarts: 10,
      restart_delay: 3000,
      max_memory_restart: '512M',
      out_file: '/var/log/autogram/prod-api-out.log',
      error_file: '/var/log/autogram/prod-api-error.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      watch: false,
      kill_timeout: 5000,
    },
  ],
};
