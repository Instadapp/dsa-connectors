import axios from "axios";
import { childLogger } from "./logger";

const logger = childLogger("utils/api");

function getApi() {
  const api = axios.create({});

  api.interceptors.request.use(
    (request) => {
      logger.info({
        msg: "Request to external API",
        req: {
          method: request.method,
          url: request.url,
          params: request.params,
          headers: request.headers,
        },
      });

      return request;
    },
    (error) => {
      logger.error({ msg: "Error while requesting external API", error });

      return Promise.reject(error);
    }
  );

  api.interceptors.response.use(
    (response) => {
      logger.info({
        msg: "Response from external API",
        req: {
          method: response.config.method,
          url: response.config.url,
          params: response.config.params,
        },
        res: {
          statusCode: response.status,
          statusText: response.statusText,
          headers: response.config.headers,
          data: response.data,
        },
      });

      return response;
    },
    (error) => {
      logger.error({ msg: "Error response from external API", error });

      return Promise.reject(error);
    }
  );

  return api;
}

export default getApi();
