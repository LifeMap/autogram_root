module.exports = {
  apps: [
    {
      name: 'autogram-web-dev',
      script: 'node_modules/.bin/next',
      args: 'start -p 4003',
      cwd: '/Users/jaykim/Documents/twms/autogram/dev/web',
      instances: 1,
      exec_mode: 'fork',
      max_restarts: 10,
      restart_delay: 3000,
      max_memory_restart: '512M',
      out_file: '/var/log/autogram/dev-web-out.log',
      error_file: '/var/log/autogram/dev-web-error.log',
      merge_logs: true,
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      watch: false,
      kill_timeout: 5000,
    },
  ],
};
