"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const check_1 = __importDefault(require("./check"));
(async function runHusky() {
    try {
        await (0, check_1.default)();
    }
    catch (error) {
        process.exit(1);
    }
})();
//# sourceMappingURL=huskyCheck.js.map