.pragma library

function isCalcLikeQuery(queryText) {
    const raw = (queryText || "").trim()
    if (raw === "")
        return false

    if (!/[0-9]/.test(raw))
        return false

    // Only allow safe arithmetic input characters.
    if (!/^[0-9+\-*/%^().,\s]+$/.test(raw))
        return false

    // Require an operator/parenthesis to avoid triggering on plain numbers.
    return /[+\-*/%^()]/.test(raw)
}

function tokenizeExpression(expr) {
    const input = expr.replace(/,/g, "").trim()
    const out = []
    let i = 0
    let prevType = "start"

    while (i < input.length) {
        const ch = input[i]

        if (/\s/.test(ch)) {
            i += 1
            continue
        }

        if (ch >= "0" && ch <= "9" || ch === ".") {
            let j = i + 1
            while (j < input.length && (/([0-9.])/.test(input[j])))
                j += 1
            const raw = input.slice(i, j)
            if ((raw.match(/\./g) || []).length > 1)
                return null
            const num = Number(raw)
            if (!Number.isFinite(num))
                return null
            out.push({ type: "number", value: num })
            prevType = "number"
            i = j
            continue
        }

        if (ch === "(" || ch === ")") {
            out.push({ type: ch })
            prevType = ch === ")" ? "number" : "("
            i += 1
            continue
        }

        if ("+-*/%^".indexOf(ch) >= 0) {
            let op = ch
            if ((ch === "+" || ch === "-") && (prevType === "start" || prevType === "operator" || prevType === "("))
                op = ch === "+" ? "u+" : "u-"
            out.push({ type: "operator", value: op })
            prevType = "operator"
            i += 1
            continue
        }

        return null
    }

    return out
}

function opPrecedence(op) {
    if (op === "u+" || op === "u-")
        return 4
    if (op === "^")
        return 3
    if (op === "*" || op === "/" || op === "%")
        return 2
    if (op === "+" || op === "-")
        return 1
    return 0
}

function opRightAssociative(op) {
    return op === "^" || op === "u+" || op === "u-"
}

function toRpn(tokens) {
    const output = []
    const ops = []

    for (const token of tokens) {
        if (token.type === "number") {
            output.push(token)
            continue
        }

        if (token.type === "(") {
            ops.push(token)
            continue
        }

        if (token.type === ")") {
            while (ops.length > 0 && ops[ops.length - 1].type !== "(")
                output.push(ops.pop())
            if (ops.length === 0)
                return null
            ops.pop()
            continue
        }

        if (token.type === "operator") {
            const prec = opPrecedence(token.value)
            const rightAssoc = opRightAssociative(token.value)
            while (ops.length > 0) {
                const top = ops[ops.length - 1]
                if (top.type !== "operator")
                    break
                const topPrec = opPrecedence(top.value)
                if ((rightAssoc && prec < topPrec) || (!rightAssoc && prec <= topPrec))
                    output.push(ops.pop())
                else
                    break
            }
            ops.push(token)
            continue
        }
    }

    while (ops.length > 0) {
        const top = ops.pop()
        if (top.type === "(" || top.type === ")")
            return null
        output.push(top)
    }

    return output
}

function evalRpn(rpn) {
    const stack = []

    for (const token of rpn) {
        if (token.type === "number") {
            stack.push(token.value)
            continue
        }

        if (token.type !== "operator")
            return null

        if (token.value === "u+" || token.value === "u-") {
            if (stack.length < 1)
                return null
            const v = stack.pop()
            stack.push(token.value === "u-" ? -v : v)
            continue
        }

        if (stack.length < 2)
            return null

        const b = stack.pop()
        const a = stack.pop()
        let v = 0
        if (token.value === "+")
            v = a + b
        else if (token.value === "-")
            v = a - b
        else if (token.value === "*")
            v = a * b
        else if (token.value === "/")
            v = a / b
        else if (token.value === "%")
            v = a % b
        else if (token.value === "^")
            v = Math.pow(a, b)
        else
            return null

        if (!Number.isFinite(v))
            return null
        stack.push(v)
    }

    if (stack.length !== 1)
        return null
    return stack[0]
}

function formatCalcValue(value) {
    const rounded = Math.round(value * 1e12) / 1e12
    return Number.isInteger(rounded) ? String(rounded) : String(rounded)
}

function calculateExpression(queryText) {
    if (!isCalcLikeQuery(queryText))
        return null

    const tokens = tokenizeExpression(queryText)
    if (!tokens || tokens.length === 0)
        return null
    const rpn = toRpn(tokens)
    if (!rpn)
        return null
    const value = evalRpn(rpn)
    if (!Number.isFinite(value))
        return null
    return {
        id: "__launcher_calc__",
        kind: "calculation",
        name: "= " + formatCalcValue(value),
        description: "Press Enter to copy result",
        exec: "",
        icon: "",
        icon_name: "",
        calc_value: formatCalcValue(value)
    }
}
