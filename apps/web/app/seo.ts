export const siteName = "Youversly"

export const siteTitle = "Youversly | Bible Verse Image Studio"

export const siteDescription =
  "Create beautiful, downloadable Bible verse images for devotionals, social posts, lock screens, and church media in minutes."

export const openGraphDescription =
  "Turn scripture references into polished Bible verse images with selectable translations, art styles, and instant PNG or JPG downloads."

export const siteKeywords = [
  "Bible verse image maker",
  "Bible verse graphics",
  "scripture images",
  "Christian social media graphics",
  "devotional images",
  "verse poster generator",
  "Youversly",
]

export function getSiteUrl() {
  const url =
    process.env.NEXT_PUBLIC_SITE_URL ||
    process.env.VERCEL_PROJECT_PRODUCTION_URL ||
    process.env.VERCEL_URL ||
    "https://youversly.com"

  return new URL(url.startsWith("http") ? url : `https://${url}`)
}
