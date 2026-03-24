module.exports = {
  default: {
    requireModule: ['ts-node/register'],
    require: ['steps/**/*.ts', 'support/**/*.ts'],
    paths: ['../stages/**/features/*.feature'],
    format: ['progress', 'json:reports/cucumber-report.json'],
    formatOptions: { snippetInterface: 'async-await' },
  },
};
