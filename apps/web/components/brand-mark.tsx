// Youversly mark: a solid open book with a thin spine.
// Source of truth lives in packages/brand/logo.svg; keep the path data in sync.
// This component is plain JSX so it renders both in the DOM and inside
// `ImageResponse` (satori) for the icon and Open Graph routes.

export const brandOrange = "#ffa500"
export const brandBlack = "#000000"

/** Tight bounds of the mark inside the 1024 logo canvas. */
export const MARK_VIEWBOX = "168 419 688 187"
export const MARK_ASPECT = 688 / 187

const LEFT_PAGE =
  "M 496 490 C 436 450 340 419 240 425 C 212 427 188 433 176 438 Q 168 441 168 450 L 168 505 Q 168 515 178 512 C 240 495 340 491 420 509 C 460 519 486 548 496 590 Z"
const RIGHT_PAGE =
  "M 528 490 C 588 450 684 419 784 425 C 812 427 836 433 848 438 Q 856 441 856 450 L 856 505 Q 856 515 846 512 C 784 495 684 491 604 509 C 564 519 538 548 528 590 Z"

type BrandMarkProps = {
  /** Rendered width in px. Height follows the mark's aspect ratio. */
  width: number
  color?: string
  className?: string
}

export function BrandMark({
  width,
  color = brandBlack,
  className,
}: BrandMarkProps) {
  const height = Math.round((width / MARK_ASPECT) * 100) / 100
  return (
    <svg
      aria-hidden="true"
      className={className}
      fill={color}
      height={height}
      viewBox={MARK_VIEWBOX}
      width={width}
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d={LEFT_PAGE} />
      <path d={RIGHT_PAGE} />
      <rect height="130" rx="12" width="24" x="500" y="476" />
    </svg>
  )
}

type BrandTileProps = {
  /** Tile edge in px. */
  size: number
  radius?: number
}

/** Orange square tile with the black mark centred, used for icons. */
export function BrandTile({ size, radius = 0 }: BrandTileProps) {
  return (
    <div
      style={{
        alignItems: "center",
        background: brandOrange,
        borderRadius: radius,
        display: "flex",
        height: size,
        justifyContent: "center",
        width: size,
      }}
    >
      <BrandMark width={Math.round(size * 0.72)} />
    </div>
  )
}
