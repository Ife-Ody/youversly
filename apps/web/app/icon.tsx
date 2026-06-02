import { ImageResponse } from "next/og"

export const size = {
  width: 512,
  height: 512,
}

export const contentType = "image/png"

export default function Icon() {
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
          borderRadius: 104,
          color: "#111111",
          display: "flex",
          fontSize: 220,
          fontWeight: 800,
          height: 368,
          justifyContent: "center",
          lineHeight: 1,
          width: 368,
        }}
      >
        Y
      </div>
    </div>,
    size
  )
}
