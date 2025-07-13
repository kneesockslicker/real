import { Client } from "@notionhq/client";
import { GetStaticProps } from "next";
import Head from "next/head";
import { useEffect } from "react";

let listNumber = 0;

// Helper to render Notion rich text with annotations (bold, italic, etc.)
const renderRichText = (richTextArr: any[]) => {
  return richTextArr.map((fragment, idx) => {
    const { annotations, plain_text } = fragment;
    const style: React.CSSProperties = {
      fontWeight: annotations.bold ? "bold" : undefined,
      fontStyle: annotations.italic ? "italic" : undefined,
      textDecoration: [
        annotations.underline ? "underline" : "",
        annotations.strikethrough ? "line-through" : "",
      ]
        .filter(Boolean)
        .join(" "),
      color:
        annotations.color && annotations.color !== "default"
          ? annotations.color
          : undefined,
    };
    return (
      <span key={idx} style={style}>
        {plain_text}
      </span>
    );
  });
};

const Block = ({ block }: { block: any }) => {
  const { type, checked, rich_text = [], annotations = {} } = block;
  let className;

  switch (type) {
    case "numbered_list_item":
      listNumber++;
      return (
        <div className="ml-1">
          <span className="text-sm">{listNumber / 2}.</span>{" "}
          {renderRichText(rich_text)}
        </div>
      );
    default:
      break;
  }

  listNumber = 0;

  switch (type) {
    case "break":
      return <div className="w-full h-4" />;
    case "heading_1":
      className = " text-lg sm:text-2xl";
      break;
    case "heading_2":
      className = "text-md sm:text-xl";
      break;
    case "heading_3":
      className = "sm:text-lg mb-1";
      break;
    case "to_do":
      return (
        <div className={className}>
          <input type="checkbox" checked={checked} readOnly />
          <span
            style={{
              marginLeft: "0.4rem",
              color: checked ? "gray" : "",
              textDecoration: checked ? "line-through" : "",
            }}
          >
            {renderRichText(rich_text)}
          </span>
        </div>
      );
    case "code":
      className = "font-mono bg-gray-800 rounded p-2 mb-5";
      return (
        <div className={className}>
          {rich_text.length > 0
            ? rich_text[0].plain_text.split("\n").map((exp: string, index: number) => (
                <div key={index}>{exp}</div>
              ))
            : null}
        </div>
      );
    case "paragraph":
      break;
    case "bulleted_list_item":
      return <div className="ml-1">&#8226; {renderRichText(rich_text)}</div>;
    default:
      break;
  }
  return <div className={className}>{renderRichText(rich_text)}</div>;
};

const TableBlock = ({ rows }: { rows: string[][] }) => {
  if (!rows || rows.length === 0) return null;
  return (
    <table className="my-4 border border-gray-500 w-full">
      <tbody>
        {rows.map((row, i) => (
          <tr key={i}>
            {row.map((cell, j) => (
              <td key={j} className="border border-gray-500 px-2 py-1">
                {cell}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
};

const ImageBlock = ({ block }: { block: { [key: string]: any } }) => {
  return (
    <>
      <img src={block.image.file.url} width={"50%"} className="mx-auto my-4" />
    </>
  );
};

const VideoBlock = ({ block }: { block: { [key: string]: any } }) => {
  if (!block.url) return null;
  // Check for YouTube/Vimeo and embed via iframe
  const isYouTube =
    block.url.includes("youtube.com") || block.url.includes("youtu.be");
  const isVimeo = block.url.includes("vimeo.com");
  if (isYouTube) {
    // Convert to embed URL
    let embedUrl = block.url;
    if (block.url.includes("watch?v=")) {
      embedUrl = block.url.replace("watch?v=", "embed/");
    } else if (block.url.includes("youtu.be/")) {
      embedUrl = block.url.replace("youtu.be/", "youtube.com/embed/");
    }
    return (
      <div className="my-4 flex justify-center">
        <iframe
          src={embedUrl}
          width="560"
          height="315"
          frameBorder="0"
          allow="autoplay; encrypted-media"
          allowFullScreen
          title="YouTube Video"
        />
      </div>
    );
  }
  if (isVimeo) {
    // Convert to embed URL
    let embedUrl = block.url;
    if (block.url.includes("vimeo.com/")) {
      const videoId = block.url.split("vimeo.com/")[1];
      embedUrl = `https://player.vimeo.com/video/${videoId}`;
    }
    return (
      <div className="my-4 flex justify-center">
        <iframe
          src={embedUrl}
          width="560"
          height="315"
          frameBorder="0"
          allow="autoplay; fullscreen"
          allowFullScreen
          title="Vimeo Video"
        />
      </div>
    );
  }
  // Otherwise, use HTML5 video tag
  return (
    <div className="my-4 flex justify-center">
      <video controls width="70%">
        <source src={block.url} />
        Your browser does not support the video tag.
      </video>
    </div>
  );
};

// ColumnListBlock recursively renders columns and their children
const ColumnListBlock = ({ columns }: { columns: any[][] }) => {
  return (
    <div className="flex gap-4 my-4">
      {columns.map((blocks, colIdx) => (
        <div key={colIdx} className="flex-1 flex flex-col gap-2">
          {blocks.map((block, idx) => {
            if (block.type === "image") return <ImageBlock block={block} key={idx} />;
            if (block.type === "video") return <VideoBlock block={block} key={idx} />;
            if (block.type === "table") return <TableBlock rows={block.rows} key={idx} />;
            if (block.type === "column_list") return <ColumnListBlock columns={block.columns} key={idx} />;
            return <Block block={block} key={idx} />;
          })}
        </div>
      ))}
    </div>
  );
};

const Post = ({
  postData,
  postProperties,
  pageId,
}: {
  postData: { [key: string]: any }[];
  postProperties: { [key: string]: any };
  pageId: string;
}) => {
  useEffect(() => {
    const update = async () => {
      try {
        await fetch(
          `https://${
            process.env.VERCEL_URL || process.env.NEXT_PUBLIC_VERCEL_URL
          }/api/views/${pageId}`,
          {
            method: "POST",
          }
        );
        return null;
      } catch (e) {
        console.log(e);
      }
    };
    update();
  }, [pageId]);

  return (
    <>
      <Head>
        <title>
          {postProperties.Name.title[0]?.plain_text || "Untitled Post"}
        </title>
      </Head>
      <div className="mt-6 sm:ml-12 sm:mt-12 flex flex-col gap-y-1 w-10/12  sm:w-3/5 md:w-1/2">
        <h1 className="text-3xl sm:text-3xl">
          {postProperties.Name.title[0]?.plain_text || "Untitled Post"}
        </h1>
        <p className="text-gray-200 text-xs sm:text-md">
          {new Date(
            postProperties["Created time"]["created_time"]
          ).toLocaleDateString("en-EN", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
          <span className="ml-6">
            views: {(postProperties.Views.number ?? 0) + 1}
          </span>
        </p>
        <br />
        {postData.map((x: any, index: number) => {
          if (x.type === "image") return <ImageBlock block={x} key={index} />;
          if (x.type === "video") return <VideoBlock block={x} key={index} />;
          if (x.type === "table") return <TableBlock rows={x.rows} key={index} />;
          if (x.type === "column_list") return <ColumnListBlock columns={x.columns} key={index} />;
          return <Block key={index} block={x} />;
        })}
      </div>
    </>
  );
};

export default Post;

export async function getStaticPaths() {
  const notion = new Client({ auth: process.env.NOTION_KEY });
  const postsResponse = await notion.databases.query({
    database_id: process.env.NOTION_POSTS_DATABASE_ID!,
  });
  const results: any = postsResponse.results;
  const paths = results.map((res: { [key: string]: any }) => {
    return {
      params: {
        id: res.id,
      },
    };
  });
  return {
    paths,
    fallback: "blocking",
  };
}

export const getStaticProps: GetStaticProps = async ({ params }) => {
  const pageId: any = params!.id;
  const notion = new Client({ auth: process.env.NOTION_KEY });

  const response = await notion.blocks.children.list({
    block_id: pageId,
    page_size: 50,
  });
  const pageResponse: any = await notion.pages.retrieve({ page_id: pageId });
  let postProperties = pageResponse.properties;

  // Helper to fetch table rows
  async function fetchTableRows(tableBlockId: string) {
    const rowsResponse = await notion.blocks.children.list({
      block_id: tableBlockId,
      page_size: 100,
    });
    return rowsResponse.results
      .filter((row: any) => row.type === "table_row")
      .map((row: any) => {
        return row.table_row.cells.map((cell: any) =>
          cell.map((rich: any) => rich.plain_text).join("")
        );
      });
  }

  // Recursive block mapping for columns and main content
  async function mapBlock(x: any): Promise<any> {
    const type = x.type;
    if (type === "image") {
      return x;
    }
    if (type === "video") {
      const url =
        x.video.type === "file"
          ? x.video.file.url
          : x.video.type === "external"
          ? x.video.external.url
          : null;
      return {
        type: "video",
        url,
        caption: x.video.caption,
      };
    }
    if (type === "table") {
      const rows = await fetchTableRows(x.id);
      return {
        type: "table",
        rows,
      };
    }
    if (type === "column_list") {
      // Fetch columns
      const columnsResponse = await notion.blocks.children.list({
        block_id: x.id,
        page_size: 100,
      });
      const columns = await Promise.all(
        columnsResponse.results
          .filter((col: any) => col.type === "column")
          .map(async (col: any) => {
            // Fetch blocks inside each column
            const colBlocksResponse = await notion.blocks.children.list({
              block_id: col.id,
              page_size: 100,
            });
            // Recursively process blocks in the column
            return Promise.all(colBlocksResponse.results.map(mapBlock));
          })
      );
      return {
        type: "column_list",
        columns,
      };
    }
    if (!x[type]?.text || x[type].text.length === 0)
      return {
        type: "break",
        annotations: {},
      };
    return {
      type,
      rich_text: x[type].text,
      checked: x[type].checked ? true : false,
    };
  }

  // Map blocks, handling tables, images, videos, columns, and rich text
  const results = await Promise.all(response.results.map(mapBlock));

  return {
    props: {
      postProperties: postProperties,
      pageId: pageId,
      postData: results,
    },
    revalidate: 10,
  };
};
