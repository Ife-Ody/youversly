import { ImageResponse } from "next/og"

export const size = {
  width: 180,
  height: 180,
}

export const contentType = "image/png"

export default function AppleIcon() {
  return new ImageResponse(
    <div
      style={{
        alignItems: "center",
        background: "#111111",
        color: "#fffaf0",
        display: "flex",
        height: "100%",
        justifyContent: "center",
        width: "100%",
      }}
    >
      <div
        style={{
          alignItems: "center",
          background: "#fffaf0",
          borderRadius: 36,
          color: "#111111",
          display: "flex",
          fontSize: 78,
          fontWeight: 800,
          height: 124,
          justifyContent: "center",
          lineHeight: 1,
          width: 124,
        }}
      >
        Y
      </div>
    </div>,
    size
  )
}
