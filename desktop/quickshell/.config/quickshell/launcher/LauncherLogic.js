.pragma library

function scoreField(field, needle, base, allowSubsequence) {
    if (!field)
        return -1

    const text = field.toLowerCase()
    if (text === needle)
        return base + 8000
    if (text.startsWith(needle))
        return base + 6000 - Math.min(2000, text.length)

    const idx = text.indexOf(needle)
    if (idx >= 0) {
        if (needle.length <= 3 && idx > 0) {
            const prev = text[idx - 1]
            const wordBoundary = (prev < "a" || prev > "z") && (prev < "0" || prev > "9")
            if (!wordBoundary)
                return -1
        }
        return base + 3500 - idx * 18
    }

    if (!allowSubsequence || needle.length < 4)
        return -1

    let last = -1
    let streak = 0
    let hits = 0
    for (let i = 0; i < needle.length; i++) {
        const pos = text.indexOf(needle[i], last + 1)
        if (pos < 0)
            return -1
        if (pos === last + 1)
            streak += 1
        else
            streak = 0
        hits += 1 + streak
        last = pos
    }
    return base + 1200 + hits * 16 - last
}

function filterApps(allApps, queryText) {
    const q = (queryText || "").toLowerCase()
    if (q === "")
        return allApps

    const scored = []
    for (const app of allApps) {
        const name = app.name ?? ""
        const desc = app.description ?? ""
        const exec = app.exec ?? ""

        const sName = scoreField(name, q, 6000, true)
        const sDesc = q.length >= 3 ? scoreField(desc, q, 2400, false) : -1
        const sExec = q.length >= 4 ? scoreField(exec, q, 1200, false) : -1
        let score = Math.max(sName, sDesc, sExec)

        if (score >= 0) {
            const launches = Number(app.launch_count ?? 0)
            const lastLaunch = Number(app.launch_last ?? 0)
            if (launches > 0) {
                const nowSec = Date.now() / 1000
                const ageDays = Math.max(0, (nowSec - lastLaunch) / 86400)
                const recency = lastLaunch > 0 ? Math.exp(-Math.LN2 * ageDays / 7) : 0
                const frequency = Math.log2(launches + 1)
                const frecency = frequency * (520 + recency * 780)
                const recencyKick = ageDays < (1 / 24) ? 200 : (ageDays < 1 ? 90 : 0)
                score += Math.min(3400, frecency + recencyKick)
            }
            scored.push({ app, score })
        }
    }

    scored.sort((a, b) => {
        if (b.score !== a.score)
            return b.score - a.score
        const an = (a.app.name ?? "").toLowerCase()
        const bn = (b.app.name ?? "").toLowerCase()
        return an.localeCompare(bn)
    })

    return scored.map(e => e.app)
}

function sanitizeExec(execLine) {
    if (!execLine)
        return ""

    let cmd = execLine.replace(/%%/g, "__QS_LITERAL_PERCENT__")
    cmd = cmd.replace(/%[A-Za-z]/g, "")
    cmd = cmd.replace(/__QS_LITERAL_PERCENT__/g, "%")
    return cmd.replace(/\s+/g, " ").trim()
}

function nextSelectionIndex(currentIndex, total, direction) {
    if (total <= 0)
        return -1

    let next = currentIndex
    if (next < 0)
        return direction > 0 ? 0 : total - 1

    if (direction > 0)
        return Math.min(total - 1, next + 1)
    return Math.max(0, next - 1)
}

function pageSelectionIndex(currentIndex, total, viewportHeight, itemHeight, direction) {
    if (total <= 0)
        return -1

    const step = Math.max(1, Math.floor(viewportHeight / itemHeight) - 1)
    let next = currentIndex < 0 ? 0 : currentIndex

    if (direction > 0)
        return Math.min(total - 1, next + step)
    return Math.max(0, next - step)
}

function clampSelectionIndex(currentIndex, total) {
    if (total <= 0)
        return -1
    return Math.max(0, Math.min(currentIndex, total - 1))
}
