export interface CompileTestFileOptions {
    sourcePath: string;
    outputDirectory: string;
    projectPath: string;
}
export declare function compileTestFile(options: CompileTestFileOptions): Promise<string>;
