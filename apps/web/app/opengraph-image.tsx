import { ImageResponse } from "next/og"

import { openGraphDescription, siteName } from "./seo"

export const alt =
  "Youversly Bible verse image studio preview with scripture poster examples"

export const size = {
  width: 1200,
  height: 630,
}

export const contentType = "image/png"

export default function OpenGraphImage() {
  return new ImageResponse(
    <div
      style={{
        background: "#111111",
        color: "#fffaf0",
        display: "flex",
        height: "100%",
        overflow: "hidden",
        padding: 64,
        position: "relative",
        width: "100%",
      }}
    >
      <div
        style={{
          background: "#1f3d35",
          display: "flex",
          height: 780,
          left: 740,
          opacity: 0.92,
          position: "absolute",
          top: -72,
          transform: "rotate(-10deg)",
          width: 420,
        }}
      />
      <div
        style={{
          background: "#e7c46b",
          display: "flex",
          height: 420,
          left: 940,
          opacity: 0.95,
          position: "absolute",
          top: 250,
          transform: "rotate(14deg)",
          width: 240,
        }}
      />
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 34,
          justifyContent: "space-between",
          position: "relative",
          width: 680,
        }}
      >
        <div
          style={{
            alignItems: "center",
            display: "flex",
            gap: 18,
          }}
        >
          <div
            style={{
              alignItems: "center",
              background: "#fffaf0",
              borderRadius: 18,
              color: "#111111",
              display: "flex",
              fontSize: 40,
              fontWeight: 800,
              height: 72,
              justifyContent: "center",
              width: 72,
            }}
          >
            Y
          </div>
          <div
            style={{
              display: "flex",
              flexDirection: "column",
            }}
          >
            <div style={{ fontSize: 34, fontWeight: 800 }}>{siteName}</div>
            <div style={{ color: "#c8bfa8", fontSize: 22 }}>
              Bible verse image studio
            </div>
          </div>
        </div>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 24,
          }}
        >
          <div
            style={{
              fontSize: 72,
              fontWeight: 900,
              letterSpacing: 0,
              lineHeight: 0.95,
            }}
          >
            Create scripture images in minutes
          </div>
          <div
            style={{
              color: "#e9dfc9",
              fontSize: 30,
              lineHeight: 1.28,
            }}
          >
            {openGraphDescription}
          </div>
        </div>
        <div
          style={{
            alignItems: "center",
            color: "#c8bfa8",
            display: "flex",
            fontSize: 24,
            gap: 18,
          }}
        >
          <span>Pick a passage</span>
          <span>Choose a style</span>
          <span>Download PNG or JPG</span>
        </div>
      </div>
      <div
        style={{
          background: "#fffaf0",
          borderRadius: 28,
          color: "#111111",
          display: "flex",
          flexDirection: "column",
          height: 410,
          justifyContent: "space-between",
          padding: 38,
          position: "absolute",
          right: 86,
          top: 92,
          transform: "rotate(5deg)",
          width: 330,
        }}
      >
        <div
          style={{
            color: "#6f664f",
            fontSize: 28,
            fontWeight: 700,
          }}
        >
          Psalm 42:1
        </div>
        <div
          style={{
            fontSize: 34,
            fontWeight: 700,
            lineHeight: 1.2,
          }}
        >
          As the hart panteth after the water brooks, so panteth my soul after
          thee.
        </div>
        <div
          style={{
            color: "#6f664f",
            fontSize: 24,
            fontWeight: 700,
          }}
        >
          Youversly
        </div>
      </div>
    </div>,
    size
  )
}
