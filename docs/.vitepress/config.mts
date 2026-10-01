import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

export default withMermaid({
  title: 'FLAP Documentation',
  base: '/FLAP/',
  markdown: {
    math: true,
    languages: ['fortran-free-form', 'fortran-fixed-form'],
    languageAlias: {
      'fortran': 'fortran-free-form',
      'f90': 'fortran-free-form',
      'f95': 'fortran-free-form',
      'f03': 'fortran-free-form',
      'f08': 'fortran-free-form',
      'f77': 'fortran-fixed-form',
    },
  },
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Guide',
        items: [
          { text: 'About',                   link: '/guide/' },
          { text: 'Features',                link: '/guide/features' },
          { text: 'Installation',            link: '/guide/install' },
          { text: 'Defining Arguments',      link: '/guide/arguments' },
          { text: 'Parsing & Getting Values',link: '/guide/parsing' },
          { text: 'Subcommands',             link: '/guide/subcommands' },
          { text: 'Advanced Features',       link: '/guide/advanced' },
          { text: 'Output Formats',          link: '/guide/output' },
          { text: 'Interactive Menus',       link: '/guide/menu' },
          { text: 'Error Codes',             link: '/guide/errors' },
          { text: 'Contributing',            link: '/guide/contributing' },
          { text: 'Upgrading',     link: '/guide/migration' },
          { text: 'Changelog',               link: '/guide/changelog' },
        ],
      },
      {
        text: 'Manual',
        items: [
          { text: 'Overview', link: '/manual/' },
          { text: 'Tutorial', link: '/manual/tutorial/01-first-cli' },
          { text: 'Cookbook', link: '/manual/cookbook' },
        ],
      },
      { text: 'API', link: '/api/' },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'About',    link: '/guide/' },
            { text: 'Features', link: '/guide/features' },
          ],
        },
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation',             link: '/guide/install' },
            { text: 'Defining Arguments',       link: '/guide/arguments' },
            { text: 'Parsing & Getting Values', link: '/guide/parsing' },
            { text: 'Subcommands',              link: '/guide/subcommands' },
            { text: 'Advanced Features',        link: '/guide/advanced' },
            { text: 'Output Formats',           link: '/guide/output' },
            { text: 'Interactive Menus',        link: '/guide/menu' },
            { text: 'Error Codes',              link: '/guide/errors' },
          ],
        },
        {
          text: 'Project',
          items: [
            { text: 'Contributing', link: '/guide/contributing' },
            { text: 'Upgrading', link: '/guide/migration' },
            { text: 'Changelog',    link: '/guide/changelog' },
          ],
        },
      ],
      '/manual/': [
        {
          text: 'Manual',
          items: [
            { text: 'Overview', link: '/manual/' },
            { text: 'Cookbook', link: '/manual/cookbook' },
          ],
        },
        {
          text: 'Tutorial',
          items: [
            { text: '1. A first command line',     link: '/manual/tutorial/01-first-cli' },
            { text: '2. Options of every kind',    link: '/manual/tutorial/02-options' },
            { text: '3. Lists and parameters',     link: '/manual/tutorial/03-lists' },
            { text: '4. Commands',                 link: '/manual/tutorial/04-commands' },
            { text: '5. Values from everywhere',   link: '/manual/tutorial/05-sources' },
            { text: '6. Validation',               link: '/manual/tutorial/06-validation' },
            { text: '7. Shipping it',              link: '/manual/tutorial/07-shipping' },
            { text: '8. Testing the command line', link: '/manual/tutorial/08-testing' },
            { text: '9. Asking the user',          link: '/manual/tutorial/09-asking' },
          ],
        },
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
          ],
        },
        ...apiSidebar,
      ],
    },
    search: {
      provider: 'local',
    },
  },
  mermaid: {},
})
