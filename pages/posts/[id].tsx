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
      color: annotations.color && annotations.color !== "default" ? annotations.color : undefined,
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
          <span className="text-sm">{listNumber / 2}.</span> {renderRichText(rich_text)}
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
  return (
    <div className={className}>
      {renderRichText(rich_text)}
    </div>
  );
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

const Post = ({
  postData,
  postProperties = postData.properties,
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
            process.env.NEXT_PUBLIC_VERCEL_URL || process.env.VERCEL_URL
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
          if (x.type === "image") {
            return <ImageBlock block={x} key={index} />;
          }
          if (x.type === "table") {
            return <TableBlock rows={x.rows} key={index} />;
          }
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

  // Map blocks, handling tables and rich text
  const results = await Promise.all(
    response.results.map(async (x: any) => {
      const type = x.type;
      if (type === "image") {
        return x;
      }
      if (type === "table") {
        // Fetch table rows
        const rows = await fetchTableRows(x.id);
        return {
          type: "table",
          rows,
        };
      }
      // Handle blocks with rich_text
      if (!x[type]?.text || x[type].text.length === 0)
        return {
          type: "break",
          annotations: {},
        };
      return {
        type,
        rich_text: x[type].text, // pass all rich text fragments
        checked: x[type].checked ? true : false,
      };
    })
  );

  return {
    props: {
      postProperties: postProperties,
      pageId: pageId,
      postData: results,
    },
    revalidate: 10,
  };
};
