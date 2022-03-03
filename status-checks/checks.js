"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const check_1 = __importDefault(require("./check"));
exports.default = [
    {
        name: "Solidity check",
        callback: async () => {
            try {
                await (0, check_1.default)();
                return "Check passed!";
            }
            catch (error) {
                throw new Error("Check failed!");
            }
        },
    },
];
//# sourceMappingURL=checks.js.map