// Regenerates the raster brand assets from the shared mark geometry:
//   apps/web/app/favicon.ico                      (32 + 16, PNG-in-ICO)
//   apps/ios/.../AppIcon.appiconset/AppIcon.png   (1024)
// Run from apps/web: `bun run brand:icons`
import { ImageResponse } from "next/og.js"
import { createElement as h } from "react"
import { writeFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, resolve } from "node:path"

const here = dirname(fileURLToPath(import.meta.url))
const LEFT =
  "M 496 490 C 436 450 340 419 240 425 C 212 427 188 433 176 438 Q 168 441 168 450 L 168 505 Q 168 515 178 512 C 240 495 340 491 420 509 C 460 519 486 548 496 590 Z"
const RIGHT =
  "M 528 490 C 588 450 684 419 784 425 C 812 427 836 433 848 438 Q 856 441 856 450 L 856 505 Q 856 515 846 512 C 784 495 684 491 604 509 C 564 519 538 548 528 590 Z"

async function tile(size, fill) {
  const w = Math.round(size * fill)
  const hgt = Math.round((w * 187) / 688)
  const el = h(
    "div",
    { style: { display: "flex", alignItems: "center", justifyContent: "center", width: size, height: size, background: "#ffa500" } },
    h(
      "svg",
      { xmlns: "http://www.w3.org/2000/svg", viewBox: "168 419 688 187", width: w, height: hgt, fill: "#000" },
      h("path", { d: LEFT }),
      h("path", { d: RIGHT }),
      h("rect", { x: 500, y: 476, width: 24, height: 130, rx: 12 })
    )
  )
  const res = new ImageResponse(el, { width: size, height: size })
  return Buffer.from(await res.arrayBuffer())
}

function ico(pngs) {
  const header = Buffer.alloc(6)
  header.writeUInt16LE(0, 0)
  header.writeUInt16LE(1, 2)
  header.writeUInt16LE(pngs.length, 4)
  let offset = 6 + 16 * pngs.length
  const dirs = pngs.map(({ size, data }) => {
    const d = Buffer.alloc(16)
    d[0] = size >= 256 ? 0 : size
    d[1] = d[0]
    d.writeUInt16LE(1, 4)
    d.writeUInt16LE(32, 6)
    d.writeUInt32LE(data.length, 8)
    d.writeUInt32LE(offset, 12)
    offset += data.length
    return d
  })
  return Buffer.concat([header, ...dirs, ...pngs.map((p) => p.data)])
}

const favicon = ico([
  { size: 32, data: await tile(32, 0.92) },
  { size: 16, data: await tile(16, 0.92) },
])
writeFileSync(resolve(here, "../app/favicon.ico"), favicon)
writeFileSync(
  resolve(here, "../../ios/Youversly/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"),
  await tile(1024, 0.72)
)
console.log("brand icons written")
