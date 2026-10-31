import { ImageResponse } from "next/og"

import { BrandTile } from "@/components/brand-mark"

export const size = {
  width: 512,
  height: 512,
}

export const contentType = "image/png"

export default function Icon() {
  return new ImageResponse(<BrandTile size={512} />, size)
}
