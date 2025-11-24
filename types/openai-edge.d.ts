declare module 'openai-edge' {
  export interface ConfigurationParameters {
    apiKey?: string
    basePath?: string
    // любые другие поля, если вдруг понадобятся
    [key: string]: any
  }

  export class Configuration {
    apiKey?: string
    basePath?: string
    [key: string]: any

    constructor(options?: ConfigurationParameters)
  }

  export class OpenAIApi {
    constructor(config: Configuration)

    // нам достаточно, чтобы TS не ругался на вызов
    createChatCompletion: (...args: any[]) => Promise<any>
  }
}

