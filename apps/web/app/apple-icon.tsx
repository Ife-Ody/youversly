import { ImageResponse } from "next/og"

import { BrandTile } from "@/components/brand-mark"

export const size = {
  width: 180,
  height: 180,
}

export const contentType = "image/png"

export default function AppleIcon() {
  return new ImageResponse(<BrandTile size={180} />, size)
}
