"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    Object.defineProperty(o, k2, { enumerable: true, get: function() { return m[k]; } });
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cp = __importStar(require("child_process"));
const node_fetch_1 = __importDefault(require("node-fetch"));
const checks_1 = __importDefault(require("./checks"));
const [owner, repo] = process.env.GITHUB_REPOSITORY.split("/");
function getCurrentCommitSha() {
    return cp
        .execSync("git rev-parse HEAD")
        .toString()
        .trim();
}
// The SHA provied by GITHUB_SHA is the merge (PR) commit.
// We need to get the current commit sha ourself.
const sha = getCurrentCommitSha();
async function setStatus(context, state, description) {
    return (0, node_fetch_1.default)(`https://api.github.com/repos/${owner}/${repo}/statuses/${sha}`, {
        method: "POST",
        body: JSON.stringify({
            state,
            description,
            context,
        }),
        headers: {
            Authorization: `Bearer ${process.env.GITHUB_TOKEN}`,
            "Content-Type": "application/json",
        },
    });
}
(async () => {
    console.log(`Starting status checks for commit ${sha}`);
    // Run in parallel
    await Promise.all(checks_1.default.map(async (check) => {
        const { name, callback } = check;
        await setStatus(name, "pending", "Running check..");
        try {
            const response = await callback();
            await setStatus(name, "success", response);
        }
        catch (err) {
            const message = err ? err.message : "Something went wrong";
            await setStatus(name, "failure", message);
        }
    }));
    console.log("Finished status checks");
})();
//# sourceMappingURL=index.js.map