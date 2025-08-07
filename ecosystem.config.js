module.exports = {
  apps: [{
    name: 'ratecard-app',
    script: './dist/index.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 5000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    max_memory_restart: '1G',
    watch: false,
    ignore_watch: [
      'node_modules',
      'logs',
      'uploads',
      '.git',
      'dist'
    ],
    restart_delay: 4000,
    max_restarts: 10,
    min_uptime: '60s',
    // Auto restart if app crashes
    autorestart: true,
    // Kill timeout
    kill_timeout: 5000,
    // Graceful start
    listen_timeout: 8000,
    // Log rotation
    log_date_format: 'YYYY-MM-DD HH:mm Z',
    merge_logs: true,
    // Performance monitoring
    pmx: true,
    // Health check
    health_check_grace_period: 10000
  }],

  deploy: {
    production: {
      user: 'ubuntu',
      host: ['your-server-ip'],
      ref: 'origin/main',
      repo: 'https://github.com/yourusername/your-repo.git',
      path: '/home/ubuntu/ratecard',
      'post-deploy': 'npm install && npm run build && pm2 reload ecosystem.config.js --env production',
      'pre-setup': 'apt update && apt install git -y'
    }
  }
};
