import fs from 'node:fs'

const [publishedPath, builtPath, outputPath] = process.argv.slice(2)
if (!publishedPath || !builtPath || !outputPath) {
  console.error('usage: node merge-repository-index.mjs PUBLISHED.json BUILT.json OUTPUT.json')
  process.exit(2)
}

const published = JSON.parse(fs.readFileSync(publishedPath, 'utf8'))
const built = JSON.parse(fs.readFileSync(builtPath, 'utf8'))
if (published.format !== 1 || built.format !== 1 || !Array.isArray(published.packages) || !Array.isArray(built.packages)) {
  throw new Error('unsupported package index format')
}

const replacementNames = new Set(built.packages.map((pkg) => pkg.name))
const merged = [...published.packages.filter((pkg) => !replacementNames.has(pkg.name)), ...built.packages]
  .sort((a, b) => a.name.localeCompare(b.name))

const lines = merged.map((pkg) => JSON.stringify(pkg)).join(',\n')
fs.writeFileSync(outputPath, `{"format":1,"packages":[\n${lines}\n]}\n`)
console.log(`Preserved ${published.packages.length - replacementNames.size + built.packages.filter((pkg) => !published.packages.some((old) => old.name === pkg.name)).length} existing record(s); refreshed ${built.packages.length} built record(s).`)
