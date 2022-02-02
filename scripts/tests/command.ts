import { execFile, spawn } from "child_process";

interface ICommand {
  readonly cmd: string;
  readonly args: string[];
  readonly env: {
    [param: string]: string;
  };
}

export async function execScript(input: ICommand): Promise<number> {
  return new Promise((resolve, reject) => {
    let cmdEnv = Object.create(process.env);
    for (let param in input.env) {
      cmdEnv[param] = input.env[param];
    }

    const proc = spawn(input.cmd, [...input.args], {
      env: cmdEnv,
      shell: true,
      stdio: "inherit",
    });

    proc.on("exit", (code) => {
      if (code !== 0) {
        reject(code);
        return;
      }

      resolve(code);
    });
  });
}
