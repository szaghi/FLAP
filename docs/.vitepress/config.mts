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
      { text: 'Home',  link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'API',   link: '/api/' },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Guide',
          items: [
            { text: 'Getting Started',         link: '/guide/' },
            { text: 'Defining Arguments',      link: '/guide/arguments' },
            { text: 'Parsing & Getting Values',link: '/guide/parsing' },
            { text: 'Nested Subcommands',      link: '/guide/subcommands' },
            { text: 'Advanced Features',       link: '/guide/advanced' },
            { text: 'Output Formats',          link: '/guide/output' },
            { text: 'Error Codes',             link: '/guide/errors' },
            { text: 'Contributing',            link: '/guide/contributing' },
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
